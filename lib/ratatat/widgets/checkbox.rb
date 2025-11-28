# typed: strict
# frozen_string_literal: true

module Ratatat
  # Checkbox toggle widget
  class Checkbox < Widget
    extend T::Sig

    CAN_FOCUS = true

    # Emitted when checked state changes
    class Changed < Message
      extend T::Sig

      sig { returns(T::Boolean) }
      attr_reader :checked

      sig { params(sender: Widget, checked: T::Boolean).void }
      def initialize(sender:, checked:)
        super(sender: sender)
        @checked = checked
      end
    end

    reactive :checked, default: false, repaint: true
    reactive :label, default: "", repaint: true

    sig { params(label: String, checked: T::Boolean, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(label = "", checked: false, id: nil, classes: [])
      super(id: id, classes: classes)
      @label = label
      @checked = checked
    end

    sig { params(message: Key).void }
    def on_key(message)
      if message.key == " " || message.key == "enter"
        toggle
        message.stop
      end
    end

    sig { void }
    def toggle
      self.checked = !checked
      parent&.dispatch(Changed.new(sender: self, checked: checked))
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      indicator = checked ? "[X]" : "[ ]"
      text = "#{indicator} #{label}"
      buffer.put_string(x, y, text[0, width])
    end
  end

  # Switch toggle widget (alternative visual style)
  class Switch < Checkbox
    extend T::Sig

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      indicator = checked ? "[ON ]" : "[OFF]"
      text = "#{indicator} #{label}"
      buffer.put_string(x, y, text[0, width])
    end
  end
end
