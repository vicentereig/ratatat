# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Keyboard event representation
  class KeyEvent < T::Struct
    extend T::Sig

    const :key, T.any(Symbol, String)
    const :modifiers, T::Set[Symbol], default: Set.new

    sig { returns(T::Boolean) }
    def ctrl? = modifiers.include?(:ctrl)

    sig { returns(T::Boolean) }
    def alt? = modifiers.include?(:alt)

    sig { returns(T::Boolean) }
    def shift? = modifiers.include?(:shift)

    sig { returns(String) }
    def to_s
      mods = modifiers.to_a.map(&:to_s).join("+")
      mods.empty? ? key.to_s : "#{mods}+#{key}"
    end
  end

  # Keyboard input handler with escape sequence parsing
  class Input
    extend T::Sig

    # Escape sequence mappings
    ESCAPE_SEQUENCES = T.let({
      # Arrow keys
      "\e[A" => :up,
      "\e[B" => :down,
      "\e[C" => :right,
      "\e[D" => :left,

      # Arrow keys (alternate)
      "\eOA" => :up,
      "\eOB" => :down,
      "\eOC" => :right,
      "\eOD" => :left,

      # Home/End/Insert/Delete/PageUp/PageDown
      "\e[H" => :home,
      "\e[F" => :end,
      "\e[2~" => :insert,
      "\e[3~" => :delete,
      "\e[5~" => :page_up,
      "\e[6~" => :page_down,

      # Home/End (alternate)
      "\e[1~" => :home,
      "\e[4~" => :end,
      "\eOH" => :home,
      "\eOF" => :end,

      # Function keys F1-F12
      "\eOP" => :f1,
      "\eOQ" => :f2,
      "\eOR" => :f3,
      "\eOS" => :f4,
      "\e[15~" => :f5,
      "\e[17~" => :f6,
      "\e[18~" => :f7,
      "\e[19~" => :f8,
      "\e[20~" => :f9,
      "\e[21~" => :f10,
      "\e[23~" => :f11,
      "\e[24~" => :f12,

      # Shift+Tab
      "\e[Z" => :shift_tab
    }.freeze, T::Hash[String, Symbol])

    # Control character mappings
    CONTROL_CHARS = T.let({
      "\x00" => [:space, [:ctrl]],
      "\x01" => [:a, [:ctrl]],
      "\x02" => [:b, [:ctrl]],
      "\x03" => [:c, [:ctrl]],
      "\x04" => [:d, [:ctrl]],
      "\x05" => [:e, [:ctrl]],
      "\x06" => [:f, [:ctrl]],
      "\x07" => [:g, [:ctrl]],
      "\x08" => :backspace,
      "\x09" => :tab,
      "\x0A" => :enter,
      "\x0B" => [:k, [:ctrl]],
      "\x0C" => [:l, [:ctrl]],
      "\x0D" => :enter,
      "\x0E" => [:n, [:ctrl]],
      "\x0F" => [:o, [:ctrl]],
      "\x10" => [:p, [:ctrl]],
      "\x11" => [:q, [:ctrl]],
      "\x12" => [:r, [:ctrl]],
      "\x13" => [:s, [:ctrl]],
      "\x14" => [:t, [:ctrl]],
      "\x15" => [:u, [:ctrl]],
      "\x16" => [:v, [:ctrl]],
      "\x17" => [:w, [:ctrl]],
      "\x18" => [:x, [:ctrl]],
      "\x19" => [:y, [:ctrl]],
      "\x1A" => [:z, [:ctrl]],
      "\x1B" => :escape,
      "\x7F" => :backspace
    }.freeze, T::Hash[String, T.any(Symbol, [Symbol, T::Array[Symbol]])])

    sig { returns(IO) }
    attr_reader :io

    sig { params(io: IO).void }
    def initialize(io: $stdin)
      @io = io
    end

    # Poll for a key event with timeout (in seconds)
    # Returns KeyEvent or nil if timeout
    sig { params(timeout_sec: Float).returns(T.nilable(KeyEvent)) }
    def poll(timeout_sec)
      ready = IO.select([@io], nil, nil, timeout_sec)
      return nil unless ready

      read_key
    end

    # Read a key event (blocking)
    sig { returns(T.nilable(KeyEvent)) }
    def read_blocking
      read_key
    end

    private

    sig { returns(T.nilable(KeyEvent)) }
    def read_key
      char = read_char
      return nil unless char

      # Check for escape sequence
      if char == "\e"
        return parse_escape_sequence
      end

      # Check for control characters
      if char.ord < 32 || char.ord == 127
        return parse_control_char(char)
      end

      # Regular character
      KeyEvent.new(key: char)
    end

    sig { returns(T.nilable(String)) }
    def read_char
      @io.read_nonblock(1)
    rescue IO::WaitReadable, EOFError
      nil
    end

    sig { params(timeout_sec: Float).returns(T.nilable(String)) }
    def read_char_timeout(timeout_sec = 0.01)
      ready = IO.select([@io], nil, nil, timeout_sec)
      return nil unless ready

      read_char
    end

    sig { returns(KeyEvent) }
    def parse_escape_sequence
      seq = +"\e"

      5.times do
        char = read_char_timeout(0.005)
        break unless char

        seq << char

        if (key = ESCAPE_SEQUENCES[seq])
          return KeyEvent.new(key: key)
        end

        if seq.length == 2 && seq[1] != "[" && seq[1] != "O"
          return KeyEvent.new(key: T.must(seq[1]), modifiers: Set[:alt])
        end
      end

      KeyEvent.new(key: :escape)
    end

    sig { params(char: String).returns(KeyEvent) }
    def parse_control_char(char)
      mapping = CONTROL_CHARS[char]
      return KeyEvent.new(key: :unknown) unless mapping

      if mapping.is_a?(Array)
        key, mods = mapping
        KeyEvent.new(key: key, modifiers: mods.to_set)
      else
        KeyEvent.new(key: mapping)
      end
    end
  end
end
