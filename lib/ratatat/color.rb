# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Color types for terminal cells.
  # Supports named ANSI colors, 256-color palette, and true color (RGB).
  module Color
    extend T::Sig

    # Union type for any color
    AnyColor = T.type_alias { T.any(Named, Indexed, Rgb) }

    # Named ANSI colors (16 standard colors + reset)
    class Named < T::Enum
      extend T::Sig

      enums do
        # Reset to terminal default
        Reset = new(:reset)

        # Standard 8 colors (codes 0-7)
        Black   = new(:black)
        Red     = new(:red)
        Green   = new(:green)
        Yellow  = new(:yellow)
        Blue    = new(:blue)
        Magenta = new(:magenta)
        Cyan    = new(:cyan)
        White   = new(:white)

        # Bright variants (codes 8-15)
        BrightBlack   = new(:bright_black)
        BrightRed     = new(:bright_red)
        BrightGreen   = new(:bright_green)
        BrightYellow  = new(:bright_yellow)
        BrightBlue    = new(:bright_blue)
        BrightMagenta = new(:bright_magenta)
        BrightCyan    = new(:bright_cyan)
        BrightWhite   = new(:bright_white)
      end

      # ANSI foreground code lookup
      FG_CODES = T.let({
        reset: 39,
        black: 30, red: 31, green: 32, yellow: 33,
        blue: 34, magenta: 35, cyan: 36, white: 37,
        bright_black: 90, bright_red: 91, bright_green: 92, bright_yellow: 93,
        bright_blue: 94, bright_magenta: 95, bright_cyan: 96, bright_white: 97
      }.freeze, T::Hash[Symbol, Integer])

      # ANSI background code lookup
      BG_CODES = T.let({
        reset: 49,
        black: 40, red: 41, green: 42, yellow: 43,
        blue: 44, magenta: 45, cyan: 46, white: 47,
        bright_black: 100, bright_red: 101, bright_green: 102, bright_yellow: 103,
        bright_blue: 104, bright_magenta: 105, bright_cyan: 106, bright_white: 107
      }.freeze, T::Hash[Symbol, Integer])

      sig { returns(Integer) }
      def fg_code
        T.must(FG_CODES[serialize])
      end

      sig { returns(Integer) }
      def bg_code
        T.must(BG_CODES[serialize])
      end
    end

    # 256-color palette (0-255)
    class Indexed
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :index

      sig { params(index: Integer).void }
      def initialize(index:)
        raise ArgumentError, "Color index must be 0-255" unless index.between?(0, 255)

        @index = index
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def ==(other)
        other.is_a?(Indexed) && @index == other.index
      end
      alias eql? ==

      sig { returns(Integer) }
      def hash
        @index.hash
      end

      sig { returns(String) }
      def fg_code
        "38;5;#{index}"
      end

      sig { returns(String) }
      def bg_code
        "48;5;#{index}"
      end
    end

    # True color (24-bit RGB)
    class Rgb
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :r, :g, :b

      sig { params(r: Integer, g: Integer, b: Integer).void }
      def initialize(r:, g:, b:)
        raise ArgumentError, "Red must be 0-255" unless r.between?(0, 255)
        raise ArgumentError, "Green must be 0-255" unless g.between?(0, 255)
        raise ArgumentError, "Blue must be 0-255" unless b.between?(0, 255)

        @r = r
        @g = g
        @b = b
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def ==(other)
        other.is_a?(Rgb) && @r == other.r && @g == other.g && @b == other.b
      end
      alias eql? ==

      sig { returns(Integer) }
      def hash
        [@r, @g, @b].hash
      end

      sig { returns(String) }
      def fg_code
        "38;2;#{r};#{g};#{b}"
      end

      sig { returns(String) }
      def bg_code
        "48;2;#{r};#{g};#{b}"
      end
    end

    class << self
      extend T::Sig

      # Create RGB color from hex string
      # Accepts: "#ff8000", "ff8000", "#f80", "f80"
      sig { params(str: String).returns(Rgb) }
      def hex(str)
        str = str.delete_prefix("#")
        r, g, b = case str.length
        when 3
          [str[0] * 2, str[1] * 2, str[2] * 2]
        when 6
          [str[0, 2], str[2, 2], str[4, 2]]
        else
          raise ArgumentError, "Invalid hex color: #{str}"
        end
        Rgb.new(r: T.must(r).to_i(16), g: T.must(g).to_i(16), b: T.must(b).to_i(16))
      end

      # Generate ANSI escape code for foreground
      sig { params(color: AnyColor).returns(String) }
      def fg_ansi(color)
        case color
        when Named then color.fg_code.to_s
        when Indexed then color.fg_code
        when Rgb then color.fg_code
        else T.absurd(color)
        end
      end

      # Generate ANSI escape code for background
      sig { params(color: AnyColor).returns(String) }
      def bg_ansi(color)
        case color
        when Named then color.bg_code.to_s
        when Indexed then color.bg_code
        when Rgb then color.bg_code
        else T.absurd(color)
        end
      end
    end
  end
end
