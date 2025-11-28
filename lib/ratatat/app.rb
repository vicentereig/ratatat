# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Application base class. Subclass and override compose/handlers.
  class App < Widget
    extend T::Sig

    BINDINGS = T.let([
      Binding.new("tab", "focus_next", "Focus next", show: false),
      Binding.new("shift_tab", "focus_previous", "Focus previous", show: false),
    ], T::Array[Binding])

    sig { returns(T.nilable(Terminal)) }
    attr_reader :terminal

    sig { returns(T.nilable(Widget)) }
    attr_reader :focused

    sig { returns(StyleSheet) }
    attr_reader :stylesheet

    sig { params(id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(id: nil, classes: [])
      super
      @running = T.let(false, T::Boolean)
      @message_queue = T.let([], T::Array[Message])
      @terminal = T.let(nil, T.nilable(Terminal))
      @input = T.let(nil, T.nilable(Input))
      @focused = T.let(nil, T.nilable(Widget))
      @timers = T.let({}, T::Hash[Integer, T::Hash[Symbol, T.untyped]])
      @timer_id = T.let(0, Integer)
      @deferred = T.let([], T::Array[T.proc.void])
      @stylesheet = T.let(load_stylesheet, StyleSheet)
      @workers = T.let({}, T::Hash[Symbol, Thread])
      @worker_results = T.let([], T::Array[Worker::Done])
      @worker_mutex = T.let(Mutex.new, Mutex)
      @post_refresh_callbacks = T.let([], T::Array[T.proc.void])
    end

    private

    sig { returns(StyleSheet) }
    def load_stylesheet
      if self.class.const_defined?(:CSS, false)
        css = self.class.const_get(:CSS, false)
        CSSParser.parse(css)
      elsif self.class.const_defined?(:CSS_PATH, false)
        path = self.class.const_get(:CSS_PATH, false)
        CSSParser.parse_file(path)
      else
        StyleSheet.new
      end
    end

    public

    sig { returns(T::Boolean) }
    def running?
      @running
    end

    # Post a message to the queue for later processing
    sig { params(message: Message).void }
    def post(message)
      @message_queue << message
    end

    # Process all pending messages
    sig { void }
    def process_messages
      while (msg = @message_queue.shift)
        handle_message(msg)
      end
    end

    # Request application exit
    sig { void }
    def exit
      post(Quit.new(sender: self))
    end

    # Set focus to a widget (or nil to clear)
    sig { params(widget: T.nilable(Widget)).void }
    def set_focus(widget)
      return if @focused == widget

      old_focused = @focused
      old_focused&.instance_variable_set(:@has_focus, false)
      old_focused&.dispatch(Blur.new(sender: self))

      @focused = widget
      @focused&.instance_variable_set(:@has_focus, true)
      @focused&.dispatch(Focus.new(sender: self))
    end

    # Move focus to next focusable widget
    sig { void }
    def focus_next
      widgets = focusable_widgets
      return if widgets.empty?

      if @focused.nil?
        set_focus(widgets.first)
      else
        idx = widgets.index(@focused) || -1
        next_idx = (idx + 1) % widgets.length
        set_focus(widgets[next_idx])
      end
    end
    alias action_focus_next focus_next

    # Move focus to previous focusable widget
    sig { void }
    def focus_previous
      widgets = focusable_widgets
      return if widgets.empty?

      if @focused.nil?
        set_focus(widgets.last)
      else
        idx = widgets.index(@focused) || 0
        prev_idx = (idx - 1) % widgets.length
        set_focus(widgets[prev_idx])
      end
    end
    alias action_focus_previous focus_previous

    # Schedule a one-shot timer
    sig { params(delay: Numeric, block: T.proc.void).returns(Integer) }
    def set_timer(delay, &block)
      id = next_timer_id
      @timers[id] = { at: Time.now + delay, block: block, repeat: false }
      id
    end

    # Schedule a repeating timer
    sig { params(period: Numeric, block: T.proc.void).returns(Integer) }
    def set_interval(period, &block)
      id = next_timer_id
      @timers[id] = { at: Time.now + period, block: block, repeat: true, period: period }
      id
    end

    # Cancel a timer
    sig { params(id: Integer).void }
    def cancel_timer(id)
      @timers.delete(id)
    end

    # Schedule callback for next tick
    sig { params(block: T.proc.void).void }
    def call_later(&block)
      @deferred << block
    end

    # Schedule callback for after next render
    sig { params(block: T.proc.void).void }
    def call_after_refresh(&block)
      @post_refresh_callbacks << block
    end

    # Process timers and deferred callbacks
    sig { void }
    def process_timers
      now = Time.now

      # Process deferred first
      pending = @deferred.dup
      @deferred.clear
      pending.each(&:call)

      # Process timers
      @timers.each do |id, timer|
        next if timer[:at] > now

        timer[:block].call

        if timer[:repeat]
          timer[:at] = now + timer[:period]
        else
          @timers.delete(id)
        end
      end
    end

    # Run a block in a background thread
    sig { params(name: Symbol, block: T.proc.returns(T.untyped)).void }
    def run_worker(name, &block)
      @workers[name] = Thread.new do
        result = nil
        error = nil
        begin
          result = block.call
        rescue StandardError => e
          error = e
        end

        # Only post result if not cancelled
        @worker_mutex.synchronize do
          if @workers.key?(name)
            @worker_results << Worker::Done.new(sender: self, name: name, result: result, error: error)
            @workers.delete(name)
          end
        end
      end
    end

    # Cancel a running worker
    sig { params(name: Symbol).void }
    def cancel_worker(name)
      @worker_mutex.synchronize do
        thread = @workers.delete(name)
        thread&.kill
      end
    end

    # Process completed workers and post their messages
    sig { void }
    def process_workers
      results = @worker_mutex.synchronize do
        pending = @worker_results.dup
        @worker_results.clear
        pending
      end

      results.each { |msg| post(msg) }
    end

    # Main event loop
    sig { params(poll_interval: Float).void }
    def run(poll_interval: 0.05)
      @terminal = Terminal.new
      @input = Input.new
      @running = true

      # Handle Ctrl+C gracefully
      old_sigint = trap("INT") { @running = false }

      @terminal.enter
      begin
        # Initialize widget tree
        send(:do_compose)
        @children.each { |child| send(:trigger_mount, child) }

        # Call on_mount for the app itself
        on_mount if respond_to?(:on_mount)

        while @running
          poll_input
          process_messages
          process_timers
          process_workers
          render_frame
          process_post_refresh
          sleep(poll_interval)
        end
      ensure
        @terminal.exit
        trap("INT", old_sigint || "DEFAULT")
      end
    end

    private

    sig { returns(Integer) }
    def next_timer_id
      @timer_id += 1
    end

    sig { void }
    def poll_input
      return unless @input

      event = @input.poll(0.01)
      return unless event

      post(Key.new(sender: self, key: event.key, modifiers: event.modifiers))
    end

    sig { void }
    def render_frame
      return unless @terminal

      @terminal.draw do |buffer|
        render(buffer)
      end
    end

    sig { void }
    def process_post_refresh
      pending = @post_refresh_callbacks.dup
      @post_refresh_callbacks.clear
      pending.each(&:call)
    end

    # Override in subclass to render content
    sig { params(buffer: Buffer).void }
    def render(buffer)
      width = @terminal&.width || 80
      height = @terminal&.height || 24
      @children.each do |child|
        child.render(buffer, x: 0, y: 0, width: width, height: height) if child.respond_to?(:render)
      end
    end

    sig { params(message: Message).void }
    def handle_message(message)
      case message
      when Quit
        @running = false
      else
        # Dispatch to children, then self
        dispatch_to_focused(message)
      end
    end

    sig { params(message: Message).void }
    def dispatch_to_focused(message)
      @focused&.dispatch(message)
      dispatch(message) unless message.stopped?
    end

    # Get all focusable widgets in tree order
    sig { returns(T::Array[Widget]) }
    def focusable_widgets
      result = T.let([], T::Array[Widget])
      collect_focusable(@children, result)
      result
    end

    sig { params(widgets: T::Array[Widget], result: T::Array[Widget]).void }
    def collect_focusable(widgets, result)
      widgets.each do |widget|
        result << widget if widget.can_focus?
        collect_focusable(widget.children, result)
      end
    end
  end
end
