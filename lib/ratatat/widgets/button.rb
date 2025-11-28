# typed: strict
# frozen_string_literal: true

module Ratatat
  # Clickable button widget
  class Button < Widget
    extend T::Sig

    CAN_FOCUS = true

    # Message emitted when button is activated
    class Pressed < Message; end

    reactive :label, default: "", repaint: true

    sig { params(label: String, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(label = "", id: nil, classes: [])
      super(id: id, classes: classes)
      @label = label
    end

    sig { params(message: Key).void }
    def on_key(message)
      if message.key == "enter" || message.key == " "
        press
        message.stop
      end
    end

    sig { void }
    def press
      parent&.dispatch(Pressed.new(sender: self))
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      display = "< #{label} >"
      # Center the button text
      padding = [(width - display.length) / 2, 0].max
      buffer.put_string(x + padding, y, display[0, width])
    end
  end
end
