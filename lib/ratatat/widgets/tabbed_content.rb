# typed: strict
# frozen_string_literal: true

module Ratatat
  # Tabbed content container with switchable panes
  class TabbedContent < Widget
    extend T::Sig

    CAN_FOCUS = true

    class TabChanged < Message
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :index

      sig { returns(String) }
      attr_reader :label

      sig { params(sender: Widget, index: Integer, label: String).void }
      def initialize(sender:, index:, label:)
        super(sender: sender)
        @index = index
        @label = label
      end
    end

    sig { returns(T::Array[String]) }
    attr_reader :labels

    reactive :active_tab, default: 0, repaint: true

    sig { params(id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(id: nil, classes: [])
      super(id: id, classes: classes)
      @labels = T.let([], T::Array[String])
      @panes = T.let([], T::Array[Widget])
      @active_tab = 0
    end

    sig { params(label: String, content: Widget).void }
    def add_tab(label, content)
      @labels << label
      @panes << content
      mount(content)
    end

    sig { returns(Integer) }
    def tab_count
      @labels.length
    end

    sig { returns(T.nilable(String)) }
    def active_label
      @labels[@active_tab]
    end

    sig { returns(T.nilable(Widget)) }
    def active_pane
      @panes[@active_tab]
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "left", "shift+tab"
        switch_tab(-1)
        message.stop
      when "right", "tab"
        switch_tab(1)
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return if height < 2

      # Render tab bar
      render_tab_bar(buffer, x, y, width)

      # Render active pane content
      pane = active_pane
      pane&.render(buffer, x: x, y: y + 1, width: width, height: height - 1) if pane.respond_to?(:render)
    end

    private

    sig { params(delta: Integer).void }
    def switch_tab(delta)
      return if @labels.empty?

      old_tab = @active_tab
      @active_tab = (@active_tab + delta) % @labels.length
      return if old_tab == @active_tab

      parent&.dispatch(TabChanged.new(sender: self, index: @active_tab, label: active_label || ""))
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer).void }
    def render_tab_bar(buffer, x, y, width)
      pos = x
      @labels.each_with_index do |label, i|
        break if pos >= x + width

        prefix = i == @active_tab ? "[" : " "
        suffix = i == @active_tab ? "]" : " "
        text = "#{prefix}#{label}#{suffix}"
        buffer.put_string(pos, y, text[0, width - (pos - x)])
        pos += text.length + 1
      end
    end
  end
end
