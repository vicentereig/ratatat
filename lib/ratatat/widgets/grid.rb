# typed: strict
# frozen_string_literal: true

module Ratatat
  # Grid layout widget
  class Grid < Widget
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :columns, :gap

    sig { params(columns: Integer, gap: Integer, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(columns: 2, gap: 0, id: nil, classes: [])
      super(id: id, classes: classes)
      @columns = columns
      @gap = gap
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return if children.empty?

      col_width = (width - (@gap * (@columns - 1))) / @columns
      rows = (children.length.to_f / @columns).ceil
      row_height = rows > 0 ? (height - (@gap * (rows - 1))) / rows : 0

      children.each_with_index do |child, i|
        col = i % @columns
        row = i / @columns

        child_x = x + (col * (col_width + @gap))
        child_y = y + (row * (row_height + @gap))

        break if child_y >= y + height

        child.render(buffer, x: child_x, y: child_y, width: col_width, height: row_height) if child.respond_to?(:render)
      end
    end
  end
end
