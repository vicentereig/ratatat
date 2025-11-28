# typed: strict
# frozen_string_literal: true

module Ratatat
  # Floating tooltip widget
  class Tooltip < Widget
    extend T::Sig

    sig { returns(String) }
    attr_reader :text

    sig { returns(Integer) }
    attr_reader :anchor_x, :anchor_y

    reactive :visible, default: false, repaint: true

    sig { params(text: String, anchor_x: Integer, anchor_y: Integer, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(text:, anchor_x: 0, anchor_y: 0, id: nil, classes: [])
      super(id: id, classes: classes)
      @text = text
      @anchor_x = anchor_x
      @anchor_y = anchor_y
      @visible = false
    end

    sig { void }
    def show
      @visible = true
    end

    sig { void }
    def hide
      @visible = false
    end

    sig { params(new_x: Integer, new_y: Integer).void }
    def move_to(new_x, new_y)
      @anchor_x = new_x
      @anchor_y = new_y
      refresh
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return unless @visible
      return if height < 3

      text_width = @text.length
      box_width = [text_width + 4, width].min
      box_height = 3

      # Draw top border
      top = "┌#{"─" * (box_width - 2)}┐"
      buffer.put_string(x, y, top[0, width])

      # Draw middle with text
      padding = (box_width - 2 - text_width) / 2
      middle = "│#{" " * padding}#{@text}#{" " * (box_width - 3 - padding - text_width)}│"
      buffer.put_string(x, y + 1, middle[0, width])

      # Draw bottom border
      bottom = "└#{"─" * (box_width - 2)}┘"
      buffer.put_string(x, y + 2, bottom[0, width])
    end
  end
end
