# typed: strict
# frozen_string_literal: true

module Ratatat
  # Inline sparkline chart widget
  class Sparkline < Widget
    extend T::Sig

    # Block characters for different heights (8 levels)
    BLOCKS = T.let([" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"].freeze, T::Array[String])

    sig { returns(T::Array[Numeric]) }
    attr_reader :data

    sig { returns(T.nilable(Integer)) }
    attr_reader :max_data_points

    sig { params(data: T::Array[Numeric], max_data_points: T.nilable(Integer), id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(data: [], max_data_points: nil, id: nil, classes: [])
      super(id: id, classes: classes)
      @data = T.let(data.dup, T::Array[Numeric])
      @max_data_points = max_data_points
    end

    sig { params(value: Numeric).void }
    def push(value)
      @data << value
      @data.shift if @max_data_points && @data.length > @max_data_points
      refresh
    end

    sig { void }
    def clear
      @data.clear
      refresh
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return if @data.empty?

      min_val = @data.min || 0
      max_val = @data.max || 0
      range = max_val - min_val

      @data.each_with_index do |value, i|
        break if i >= width

        # Normalize to 0-8 range
        normalized = if range == 0
                       4 # Middle if all values same
                     else
                       ((value - min_val) / range.to_f * 8).round
                     end

        block = BLOCKS[normalized.clamp(0, 8)] || BLOCKS[0]
        buffer.put_string(x + i, y, block || " ")
      end
    end
  end
end
