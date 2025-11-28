# typed: strict
# frozen_string_literal: true

module Ratatat
  # Tabular data display with navigation
  class DataTable < Widget
    extend T::Sig

    CAN_FOCUS = true

    # Emitted when a row is selected (Enter pressed)
    class RowSelected < Message
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :index

      sig { returns(T::Array[String]) }
      attr_reader :row

      sig { params(sender: Widget, index: Integer, row: T::Array[String]).void }
      def initialize(sender:, index:, row:)
        super(sender: sender)
        @index = index
        @row = row
      end
    end

    sig { returns(T::Array[String]) }
    attr_reader :columns

    sig { returns(T::Array[T::Array[String]]) }
    attr_reader :rows

    reactive :cursor_row, default: 0, repaint: true

    sig do
      params(
        columns: T::Array[String],
        rows: T::Array[T::Array[String]],
        id: T.nilable(String),
        classes: T::Array[String]
      ).void
    end
    def initialize(columns: [], rows: [], id: nil, classes: [])
      super(id: id, classes: classes)
      @columns = columns
      @rows = T.let(rows.dup, T::Array[T::Array[String]])
      @cursor_row = 0
    end

    sig { params(row: T::Array[String]).void }
    def add_row(row)
      @rows << row
      refresh
    end

    sig { void }
    def clear_rows
      @rows.clear
      @cursor_row = 0
      refresh
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "down", "j"
        move_cursor(1)
        message.stop
      when "up", "k"
        move_cursor(-1)
        message.stop
      when "enter"
        select_row
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return if @columns.empty?

      col_width = width / @columns.length

      # Render header
      @columns.each_with_index do |col, i|
        buffer.put_string(x + (i * col_width), y, col[0, col_width])
      end

      # Render rows
      @rows.each_with_index do |row, row_idx|
        row_y = y + 1 + row_idx
        break if row_y >= y + height

        row.each_with_index do |cell, col_idx|
          break if col_idx >= @columns.length

          prefix = row_idx == @cursor_row ? "> " : "  "
          text = col_idx == 0 ? "#{prefix}#{cell}" : cell
          buffer.put_string(x + (col_idx * col_width), row_y, text[0, col_width])
        end
      end
    end

    private

    sig { params(delta: Integer).void }
    def move_cursor(delta)
      return if @rows.empty?

      @cursor_row = (@cursor_row + delta).clamp(0, @rows.length - 1)
    end

    sig { void }
    def select_row
      return if @rows.empty? || @cursor_row >= @rows.length

      row = @rows[@cursor_row]
      parent&.dispatch(RowSelected.new(sender: self, index: @cursor_row, row: row || []))
    end
  end
end
