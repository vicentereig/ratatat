# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Text modifiers as a T::Enum for type safety
  class Modifier < T::Enum
    extend T::Sig

    enums do
      None          = new
      Bold          = new
      Dim           = new
      Italic        = new
      Underline     = new
      Blink         = new
      Reverse       = new
      Hidden        = new
      Strikethrough = new
    end

    # ANSI codes for enabling modifiers
    ENABLE_CODES = T.let({
      Bold => 1,
      Dim => 2,
      Italic => 3,
      Underline => 4,
      Blink => 5,
      Reverse => 7,
      Hidden => 8,
      Strikethrough => 9
    }.freeze, T::Hash[Modifier, Integer])

    # ANSI codes for disabling modifiers
    DISABLE_CODES = T.let({
      Bold => 22,
      Dim => 22,
      Italic => 23,
      Underline => 24,
      Blink => 25,
      Reverse => 27,
      Hidden => 28,
      Strikethrough => 29
    }.freeze, T::Hash[Modifier, Integer])

    sig { returns(T.nilable(Integer)) }
    def enable_code
      ENABLE_CODES[self]
    end

    sig { returns(T.nilable(Integer)) }
    def disable_code
      DISABLE_CODES[self]
    end
  end

  # A single cell in the terminal buffer.
  # Immutable struct containing symbol, colors, and modifiers.
  class Cell < T::Struct
    extend T::Sig

    const :symbol, String, default: " "
    const :fg, Color::AnyColor, default: Color::Named::Reset
    const :bg, Color::AnyColor, default: Color::Named::Reset
    const :modifiers, T::Set[Modifier], default: Set.new
    const :skip, T::Boolean, default: false

    # Empty cell constant
    EMPTY = T.let(new, Cell)

    # Display width of this cell (1 for most chars, 2 for CJK/emoji)
    # Cached for performance
    sig { returns(Integer) }
    def width
      @_width ||= compute_width
    end

    private

    sig { returns(Integer) }
    def compute_width
      return 1 if symbol.empty?

      # Fast path for ASCII
      ord = symbol.ord
      return 1 if ord < 128

      # Use unicode-display_width if available
      if defined?(Unicode::DisplayWidth)
        Unicode::DisplayWidth.of(symbol)
      else
        wide_char?(ord) ? 2 : 1
      end
    end

    public

    # Normalize symbol for comparison (empty -> space)
    sig { returns(String) }
    def normalized_symbol
      symbol.empty? ? " " : symbol
    end

    # Check if cell has a modifier
    sig { params(mod: Modifier).returns(T::Boolean) }
    def has_modifier?(mod)
      modifiers.include?(mod)
    end

    sig { returns(T::Boolean) }
    def bold? = has_modifier?(Modifier::Bold)

    sig { returns(T::Boolean) }
    def italic? = has_modifier?(Modifier::Italic)

    sig { returns(T::Boolean) }
    def underline? = has_modifier?(Modifier::Underline)

    sig { returns(T::Boolean) }
    def dim? = has_modifier?(Modifier::Dim)

    sig { returns(T::Boolean) }
    def reverse? = has_modifier?(Modifier::Reverse)

    # Create a new cell with updated attributes
    sig { params(attrs: T.untyped).returns(Cell) }
    def with(**attrs)
      Cell.new(
        symbol: attrs.fetch(:symbol, symbol),
        fg: attrs.fetch(:fg, fg),
        bg: attrs.fetch(:bg, bg),
        modifiers: attrs.fetch(:modifiers, modifiers),
        skip: attrs.fetch(:skip, skip)
      )
    end

    # Visual equality (for diffing)
    sig { params(other: T.untyped).returns(T::Boolean) }
    def visually_equal?(other)
      return false unless other.is_a?(Cell)

      normalized_symbol == other.normalized_symbol &&
        fg == other.fg &&
        bg == other.bg &&
        modifiers == other.modifiers
    end

    private

    # Simple check for wide characters (CJK ranges, emoji)
    sig { params(codepoint: Integer).returns(T::Boolean) }
    def wide_char?(codepoint)
      # CJK Unified Ideographs
      (codepoint >= 0x4E00 && codepoint <= 0x9FFF) ||
        # CJK Extension A
        (codepoint >= 0x3400 && codepoint <= 0x4DBF) ||
        # Hangul Syllables
        (codepoint >= 0xAC00 && codepoint <= 0xD7AF) ||
        # Fullwidth Forms
        (codepoint >= 0xFF00 && codepoint <= 0xFFEF) ||
        # Emoji
        (codepoint >= 0x1F300 && codepoint <= 0x1F9FF)
    end
  end
end
