# typed: strict
# frozen_string_literal: true

require "stringio"
require "sorbet-runtime"

module Ratatat
  # ANSI terminal backend for rendering buffer diffs.
  # Optimizes output by batching cursor moves and style changes.
  class AnsiBackend
    extend T::Sig

    # ANSI escape sequences
    ESC = "\e["
    RESET = "#{ESC}0m"
    HIDE_CURSOR = "#{ESC}?25l"
    SHOW_CURSOR = "#{ESC}?25h"
    CLEAR_SCREEN = "#{ESC}2J"
    MOVE_HOME = "#{ESC}H"
    ALTERNATE_SCREEN = "#{ESC}?1049h"
    MAIN_SCREEN = "#{ESC}?1049l"

    sig { returns(IO) }
    attr_reader :io

    sig { params(io: IO).void }
    def initialize(io: $stdout)
      @io = io
      @current_fg = T.let(nil, T.nilable(Color::AnyColor))
      @current_bg = T.let(nil, T.nilable(Color::AnyColor))
      @current_modifiers = T.let(Set.new, T::Set[Modifier])
    end

    # Draw a list of updates from Buffer#diff
    # updates: Array of [x, y, Cell]
    sig { params(updates: T::Array[[Integer, Integer, Cell]]).void }
    def draw(updates)
      return if updates.empty?

      output = StringIO.new
      last_x = T.let(nil, T.nilable(Integer))
      last_y = T.let(nil, T.nilable(Integer))

      updates.each do |x, y, cell|
        # OPTIMIZATION 1: Skip cursor move if adjacent to previous position
        unless last_x && last_y && y == last_y && x == last_x + 1
          output << move_to(x, y)
        end
        last_x = x
        last_y = y

        # OPTIMIZATION 2: Only emit style changes when needed
        output << style_codes(cell)

        # Write the character
        output << cell.normalized_symbol
      end

      # Reset styles at end
      output << RESET
      @current_fg = nil
      @current_bg = nil
      @current_modifiers = Set.new

      # Single write to terminal
      @io.write(output.string)
    end

    # Move cursor to position (ANSI is 1-indexed)
    sig { params(x: Integer, y: Integer).returns(String) }
    def move_to(x, y)
      "#{ESC}#{y + 1};#{x + 1}H"
    end

    # Enter alternate screen buffer
    sig { void }
    def enter_alternate_screen
      @io.write(ALTERNATE_SCREEN)
    end

    # Leave alternate screen buffer
    sig { void }
    def leave_alternate_screen
      @io.write(MAIN_SCREEN)
    end

    # Hide cursor
    sig { void }
    def hide_cursor
      @io.write(HIDE_CURSOR)
    end

    # Show cursor
    sig { void }
    def show_cursor
      @io.write(SHOW_CURSOR)
    end

    # Clear entire screen
    sig { void }
    def clear
      @io.write("#{CLEAR_SCREEN}#{MOVE_HOME}")
    end

    # Flush output buffer
    sig { void }
    def flush
      @io.flush
    end

    # Reset all styles
    sig { void }
    def reset_style
      @io.write(RESET)
      @current_fg = nil
      @current_bg = nil
      @current_modifiers = Set.new
    end

    private

    # Generate style escape codes for a cell, optimized to only emit changes
    sig { params(cell: Cell).returns(String) }
    def style_codes(cell)
      codes = T.let([], T::Array[T.any(String, Integer)])

      # Handle modifiers
      modifier_codes = modifier_diff(cell.modifiers)
      codes.concat(modifier_codes) unless modifier_codes.empty?

      # Handle foreground color
      if cell.fg != @current_fg
        codes << Color.fg_ansi(cell.fg)
        @current_fg = cell.fg
      end

      # Handle background color
      if cell.bg != @current_bg
        codes << Color.bg_ansi(cell.bg)
        @current_bg = cell.bg
      end

      return "" if codes.empty?

      "#{ESC}#{codes.join(";")}m"
    end

    # Calculate modifier changes and return ANSI codes
    sig { params(new_modifiers: T::Set[Modifier]).returns(T::Array[Integer]) }
    def modifier_diff(new_modifiers)
      return [] if new_modifiers == @current_modifiers

      codes = T.let([], T::Array[Integer])

      # Find modifiers that were turned off
      @current_modifiers.each do |mod|
        unless new_modifiers.include?(mod)
          code = mod.disable_code
          codes << code if code
        end
      end

      # Find modifiers that were turned on
      new_modifiers.each do |mod|
        unless @current_modifiers.include?(mod)
          code = mod.enable_code
          codes << code if code
        end
      end

      @current_modifiers = new_modifiers
      codes
    end
  end
end
