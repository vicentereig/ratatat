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
    # Optimized hot path - avoids method calls and type checks in inner loop.
    sig { params(other: Buffer).returns(T::Array[[Integer, Integer, Cell]]) }
    def diff(other)
      raise ArgumentError, "Buffer size mismatch" unless @width == other.width && @height == other.height

      updates = []
      invalidated = 0  # Cells invalidated by previous wide char changing
      to_skip = 0      # Cells to skip (continuation of current wide char)

      # Cache for inner loop
      prev_cells = @cells
      curr_cells = other.cells
      width = @width
      total = prev_cells.length

      x = 0
      y = 0
      i = 0

      while i < total
        prev_cell = prev_cells[i]
        curr_cell = curr_cells[i]

        # Fast path: check if we should emit this cell
        # Skip if: marked to skip, is continuation cell, or unchanged and not invalidated
        unless curr_cell.skip || to_skip > 0
          # Inline visually_equal? check for speed
          prev_sym = prev_cell.symbol
          curr_sym = curr_cell.symbol
          prev_sym = " " if prev_sym.empty?
          curr_sym = " " if curr_sym.empty?

          changed = invalidated > 0 ||
                    prev_sym != curr_sym ||
                    prev_cell.fg != curr_cell.fg ||
                    prev_cell.bg != curr_cell.bg ||
                    prev_cell.modifiers != curr_cell.modifiers

          updates << [x, y, curr_cell] if changed
        end

        # Calculate widths for wide char tracking
        # Fast path: ASCII chars (ord < 128) always have width 1
        curr_sym = curr_cell.symbol
        prev_sym = prev_cell.symbol
        curr_ord = curr_sym.empty? ? 32 : curr_sym.ord
        prev_ord = prev_sym.empty? ? 32 : prev_sym.ord

        if curr_ord < 128 && prev_ord < 128
          # ASCII fast path - both width 1, no wide char handling needed
          to_skip = 0
          invalidated = invalidated > 0 ? invalidated - 1 : 0
        else
          # Wide char path - need actual width calculation
          curr_width = curr_cell.width
          prev_width = prev_cell.width

          # Track cells to skip (continuation of current wide char)
          to_skip = curr_width > 1 ? curr_width - 1 : 0

          # Track invalidated cells (when a wide char changes width)
          affected = curr_width > prev_width ? curr_width : prev_width
          invalidated = invalidated > affected ? invalidated - 1 : affected - 1
          invalidated = 0 if invalidated < 0
        end

        # Update position (faster than pos_of)
        x += 1
        if x >= width
          x = 0
          y += 1
        end

        i += 1
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
