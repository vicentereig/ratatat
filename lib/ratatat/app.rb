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

    sig { params(id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(id: nil, classes: [])
      super
      @running = T.let(false, T::Boolean)
      @message_queue = T.let([], T::Array[Message])
      @terminal = T.let(nil, T.nilable(Terminal))
      @input = T.let(nil, T.nilable(Input))
      @focused = T.let(nil, T.nilable(Widget))
    end

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

    # Main event loop
    sig { params(poll_interval: Float).void }
    def run(poll_interval: 0.05)
      @terminal = Terminal.new
      @input = Input.new
      @running = true

      @terminal.enter
      begin
        while @running
          poll_input
          process_messages
          render_frame
          sleep(poll_interval)
        end
      ensure
        @terminal.exit
      end
    end

    private

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

    # Override in subclass to render content
    sig { params(buffer: Buffer).void }
    def render(buffer)
      @children.each { |child| child.render(buffer) if child.respond_to?(:render) }
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
