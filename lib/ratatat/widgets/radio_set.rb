# typed: strict
# frozen_string_literal: true

module Ratatat
  # Exclusive selection radio button group
  class RadioSet < Widget
    extend T::Sig

    CAN_FOCUS = true

    class Changed < Message
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :selected

      sig { returns(String) }
      attr_reader :value

      sig { params(sender: Widget, selected: Integer, value: String).void }
      def initialize(sender:, selected:, value:)
        super(sender: sender)
        @selected = selected
        @value = value
      end
    end

    sig { returns(T::Array[String]) }
    attr_reader :options

    reactive :selected, default: 0, repaint: true
    reactive :highlight, default: 0, repaint: true

    sig { params(options: T::Array[String], selected: Integer, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(options: [], selected: 0, id: nil, classes: [])
      super(id: id, classes: classes)
      @options = options
      @selected = selected
      @highlight = selected
    end

    sig { returns(T.nilable(String)) }
    def selected_option
      @options[@selected]
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "up", "k"
        move_selection(-1)
        message.stop
      when "down", "j"
        move_selection(1)
        message.stop
      when " ", "enter"
        emit_changed
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      @options.each_with_index do |option, i|
        break if i >= height

        indicator = i == @selected ? "(*)" : "( )"
        prefix = i == @highlight ? "> " : "  "
        text = "#{prefix}#{indicator} #{option}"
        buffer.put_string(x, y + i, text[0, width])
      end
    end

    private

    sig { params(delta: Integer).void }
    def move_selection(delta)
      return if @options.empty?

      @selected = (@selected + delta) % @options.length
      @highlight = @selected
    end

    sig { void }
    def emit_changed
      return if @options.empty?

      parent&.dispatch(Changed.new(sender: self, selected: @selected, value: selected_option || ""))
    end
  end
end
