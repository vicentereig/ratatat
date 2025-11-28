# typed: strict
# frozen_string_literal: true

module Ratatat
  # Dropdown-style select widget
  class Select < Widget
    extend T::Sig

    CAN_FOCUS = true

    # Emitted when selection changes
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

    reactive :selected, default: 0, repaint: true

    sig { returns(T::Array[String]) }
    attr_reader :options

    sig do
      params(
        options: T::Array[String],
        selected: Integer,
        id: T.nilable(String),
        classes: T::Array[String]
      ).void
    end
    def initialize(options: [], selected: 0, id: nil, classes: [])
      super(id: id, classes: classes)
      @options = options
      @selected = selected
    end

    sig { returns(T.nilable(String)) }
    def selected_option
      @options[@selected]
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "down", "j"
        move_selection(1)
        message.stop
      when "up", "k"
        move_selection(-1)
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      text = "[#{selected_option || ""}]"
      buffer.put_string(x, y, text[0, width])
    end

    private

    sig { params(delta: Integer).void }
    def move_selection(delta)
      return if @options.empty?

      old = @selected
      @selected = (@selected + delta) % @options.length
      return if old == @selected

      parent&.dispatch(Changed.new(sender: self, selected: @selected, value: selected_option || ""))
    end
  end

  # List showing all options with selection marker
  class SelectionList < Select
    extend T::Sig

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      @options.each_with_index do |option, i|
        break if i >= height

        marker = i == @selected ? "> " : "  "
        text = "#{marker}#{option}"
        buffer.put_string(x, y + i, text[0, width])
      end
    end
  end
end
