# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # A 2D grid of cells representing a terminal screen or region.
  # Supports efficient diffing to minimize terminal I/O.
  class Buffer
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :width, :height

    sig { returns(T::Array[Cell]) }
    attr_reader :cells

    sig { params(width: Integer, height: Integer).void }
    def initialize(width, height)
      @width = width
      @height = height
      @cells = T.let(Array.new(width * height) { Cell::EMPTY }, T::Array[Cell])
    end

    # Get cell at (x, y) coordinates
    sig { params(x: Integer, y: Integer).returns(T.nilable(Cell)) }
    def get(x, y)
      return nil unless in_bounds?(x, y)

      @cells[index_of(x, y)]
    end

    # Alias for get
    sig { params(x: Integer, y: Integer).returns(T.nilable(Cell)) }
    def [](x, y)
      get(x, y)
    end

    # Set cell at (x, y) coordinates
    sig { params(x: Integer, y: Integer, cell: Cell).void }
    def set(x, y, cell)
      return unless in_bounds?(x, y)

      @cells[index_of(x, y)] = cell
    end

    # Alias for set
    sig { params(x: Integer, y: Integer, cell: Cell).void }
    def []=(x, y, cell)
      set(x, y, cell)
    end

    # Convert (x, y) to linear index
    sig { params(x: Integer, y: Integer).returns(Integer) }
    def index_of(x, y)
      y * @width + x
    end

    # Convert linear index to (x, y)
    sig { params(index: Integer).returns([Integer, Integer]) }
    def pos_of(index)
      [index % @width, index / @width]
    end

    # Check if coordinates are within bounds
    sig { params(x: Integer, y: Integer).returns(T::Boolean) }
    def in_bounds?(x, y)
      x >= 0 && x < @width && y >= 0 && y < @height
    end

    # Write a string at position with optional styling
    sig do
      params(
        x: Integer,
        y: Integer,
        text: String,
        fg: Color::AnyColor,
        bg: Color::AnyColor,
        modifiers: T::Set[Modifier]
      ).void
    end
    def put_string(x, y, text, fg: Color::Named::Reset, bg: Color::Named::Reset, modifiers: Set.new)
      return unless in_bounds?(x, y)

      col = x
      text.each_grapheme_cluster do |grapheme|
        break unless col < @width

        cell = Cell.new(symbol: grapheme, fg: fg, bg: bg, modifiers: modifiers)
        set(col, y, cell)

        # Handle wide characters
        char_width = cell.width
        col += 1

        # Mark continuation cells for wide chars
        if char_width > 1 && col < @width
          cont_cell = Cell.new(symbol: "", fg: fg, bg: bg, modifiers: modifiers)
          set(col, y, cont_cell)
          col += 1
        end
      end
    end

    # Clear buffer to empty cells
    sig { void }
    def clear
      @cells = Array.new(@width * @height) { Cell::EMPTY }
    end

    # Resize buffer, preserving content where possible
    sig { params(new_width: Integer, new_height: Integer).void }
    def resize(new_width, new_height)
      return if new_width == @width && new_height == @height

      new_cells = Array.new(new_width * new_height) { Cell::EMPTY }

      # Copy existing content
      [height, new_height].min.times do |y|
        [width, new_width].min.times do |x|
          old_idx = y * @width + x
          new_idx = y * new_width + x
          new_cells[new_idx] = T.must(@cells[old_idx])
        end
      end

      @width = new_width
      @height = new_height
      @cells = new_cells
    end

    # Compute diff between this buffer (previous) and another (current).
    # Returns array of [x, y, cell] for cells that changed.
    #
    # This implements Ratatui's diffing algorithm with multi-width char handling.
    sig { params(other: Buffer).returns(T::Array[[Integer, Integer, Cell]]) }
    def diff(other)
      raise ArgumentError, "Buffer size mismatch" unless @width == other.width && @height == other.height

      updates = T.let([], T::Array[[Integer, Integer, Cell]])
      invalidated = 0  # Cells invalidated by previous wide char changing
      to_skip = 0      # Cells to skip (continuation of current wide char)

      @cells.each_with_index do |prev_cell, i|
        curr_cell = T.must(other.cells[i])

        # Determine if we should emit this cell:
        # 1. Not marked to skip
        # 2. Either changed OR invalidated by a previous wide char
        # 3. Not a continuation cell of the current wide char
        should_emit = !curr_cell.skip &&
                      (!curr_cell.visually_equal?(prev_cell) || invalidated.positive?) &&
                      to_skip.zero?

        if should_emit
          x, y = pos_of(i)
          updates << [x, y, curr_cell]
        end

        # Calculate widths for tracking
        curr_width = curr_cell.width
        prev_width = prev_cell.width

        # Track cells to skip (continuation of current wide char)
        to_skip = [curr_width - 1, 0].max

        # Track invalidated cells (when a wide char changes width)
        affected = [curr_width, prev_width].max
        invalidated = [affected, invalidated].max - 1
        invalidated = [invalidated, 0].max
      end

      updates
    end

    # Debug: render buffer to string (for testing)
    sig { returns(String) }
    def to_text
      lines = T.let([], T::Array[String])
      @height.times do |y|
        line = +""
        @width.times do |x|
          cell = get(x, y)
          next unless cell

          sym = cell.normalized_symbol
          line << (sym.empty? ? " " : sym)
        end
        lines << line.rstrip
      end
      lines.join("\n")
    end

    sig { returns(String) }
    def to_s
      "Buffer(#{@width}x#{@height})"
    end
  end
end
