# typed: strict
# frozen_string_literal: true

module Ratatat
  # Modal dialog widget
  class Modal < Widget
    extend T::Sig

    CAN_FOCUS = true

    # Emitted when modal is closed
    class Closed < Message; end

    # Emitted when a button is pressed
    class ButtonPressed < Message
      extend T::Sig

      sig { returns(String) }
      attr_reader :button

      sig { returns(Integer) }
      attr_reader :index

      sig { params(sender: Widget, button: String, index: Integer).void }
      def initialize(sender:, button:, index:)
        super(sender: sender)
        @button = button
        @index = index
      end
    end

    reactive :title, default: "", repaint: true
    reactive :body, default: "", repaint: true
    reactive :selected_button, default: 0, repaint: true

    sig { returns(T::Array[String]) }
    attr_reader :buttons

    sig do
      params(
        title: String,
        body: String,
        buttons: T::Array[String],
        id: T.nilable(String),
        classes: T::Array[String]
      ).void
    end
    def initialize(title: "", body: "", buttons: [], id: nil, classes: [])
      super(id: id, classes: classes)
      @title = title
      @body = body
      @buttons = buttons
      @selected_button = 0
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "escape"
        close
        message.stop
      when "enter"
        press_button
        message.stop
      when "tab"
        next_button
        message.stop
      when "shift_tab"
        prev_button
        message.stop
      end
    end

    sig { void }
    def close
      parent&.dispatch(Closed.new(sender: self))
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      # Draw border
      draw_border(buffer, x, y, width, height)

      # Draw title
      title_x = x + (width - @title.length) / 2
      buffer.put_string(title_x, y, @title) if title_x >= x

      # Draw body
      if height > 3
        body_lines = @body.split("\n")
        body_lines.each_with_index do |line, i|
          break if i + 2 >= height - 1

          buffer.put_string(x + 2, y + 2 + i, line[0, width - 4])
        end
      end

      # Draw buttons at bottom
      render_buttons(buffer, x, y + height - 2, width) if height > 2 && !@buttons.empty?
    end

    private

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def draw_border(buffer, x, y, width, height)
      # Top
      buffer.put_string(x, y, "┌" + "─" * (width - 2) + "┐")

      # Sides
      (1...height - 1).each do |i|
        buffer.put_string(x, y + i, "│")
        buffer.put_string(x + width - 1, y + i, "│")
      end

      # Bottom
      buffer.put_string(x, y + height - 1, "└" + "─" * (width - 2) + "┘")
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer).void }
    def render_buttons(buffer, x, y, width)
      btn_strs = @buttons.each_with_index.map do |btn, i|
        if i == @selected_button
          "[ #{btn} ]"
        else
          "  #{btn}  "
        end
      end

      total = btn_strs.join(" ").length
      start_x = x + (width - total) / 2

      current_x = start_x
      btn_strs.each do |btn_str|
        buffer.put_string(current_x, y, btn_str) if current_x >= x
        current_x += btn_str.length + 1
      end
    end

    sig { void }
    def next_button
      return if @buttons.empty?

      @selected_button = (@selected_button + 1) % @buttons.length
    end

    sig { void }
    def prev_button
      return if @buttons.empty?

      @selected_button = (@selected_button - 1) % @buttons.length
    end

    sig { void }
    def press_button
      return if @buttons.empty?

      button = @buttons[@selected_button]
      parent&.dispatch(ButtonPressed.new(sender: self, button: button || "", index: @selected_button)) if button
    end
  end
end
