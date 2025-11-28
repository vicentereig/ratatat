# typed: strict
# frozen_string_literal: true

module Ratatat
  # Single-line text input widget
  class TextInput < Widget
    extend T::Sig

    CAN_FOCUS = true

    # Emitted when value changes
    class Changed < Message
      extend T::Sig

      sig { returns(String) }
      attr_reader :value

      sig { params(sender: Widget, value: String).void }
      def initialize(sender:, value:)
        super(sender: sender)
        @value = value
      end
    end

    # Emitted when Enter is pressed
    class Submitted < Message
      extend T::Sig

      sig { returns(String) }
      attr_reader :value

      sig { params(sender: Widget, value: String).void }
      def initialize(sender:, value:)
        super(sender: sender)
        @value = value
      end
    end

    reactive :value, default: "", repaint: true
    reactive :placeholder, default: "", repaint: true

    sig { returns(Integer) }
    attr_reader :cursor

    sig do
      params(
        value: String,
        placeholder: String,
        id: T.nilable(String),
        classes: T::Array[String]
      ).void
    end
    def initialize(value: "", placeholder: "", id: nil, classes: [])
      super(id: id, classes: classes)
      @value = value
      @placeholder = placeholder
      @cursor = T.let(value.length, Integer)
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "backspace"
        delete_backward
        message.stop
      when "delete"
        delete_forward
        message.stop
      when "left"
        move_cursor(-1)
        message.stop
      when "right"
        move_cursor(1)
        message.stop
      when "home"
        @cursor = 0
        message.stop
      when "end"
        @cursor = value.length
        message.stop
      when "enter"
        submit
        message.stop
      else
        insert_char(message.key) if message.key.length == 1
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      display = value.empty? ? placeholder : value
      buffer.put_string(x, y, display[0, width] || "")
    end

    private

    sig { params(char: String).void }
    def insert_char(char)
      new_value = value.dup
      new_value.insert(@cursor, char)
      @cursor += 1
      self.value = new_value
      emit_changed
    end

    sig { void }
    def delete_backward
      return if @cursor == 0

      new_value = value.dup
      new_value.slice!(@cursor - 1)
      @cursor -= 1
      self.value = new_value
      emit_changed
    end

    sig { void }
    def delete_forward
      return if @cursor >= value.length

      new_value = value.dup
      new_value.slice!(@cursor)
      self.value = new_value
      emit_changed
    end

    sig { params(delta: Integer).void }
    def move_cursor(delta)
      @cursor = (@cursor + delta).clamp(0, value.length)
    end

    sig { void }
    def emit_changed
      parent&.dispatch(Changed.new(sender: self, value: value))
    end

    sig { void }
    def submit
      parent&.dispatch(Submitted.new(sender: self, value: value))
    end
  end
end
