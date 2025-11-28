# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Parses CSS-like stylesheets into StyleSheet objects
  module CSSParser
    extend T::Sig

    class ParseError < StandardError; end

    sig { params(css: String).returns(StyleSheet) }
    def self.parse(css)
      sheet = StyleSheet.new
      tokens = tokenize(css)
      parse_rules(tokens, sheet)
      sheet
    end

    sig { params(path: String).returns(StyleSheet) }
    def self.parse_file(path)
      parse(File.read(path))
    end

    class << self
      extend T::Sig

      private

      sig { params(css: String).returns(T::Array[String]) }
      def tokenize(css)
        # Remove comments
        css = css.gsub(%r{/\*.*?\*/}m, "")

        # Split into tokens preserving structure
        # Only treat : as separator inside blocks (for property:value)
        tokens = []
        current = ""
        in_block = false

        css.each_char do |char|
          case char
          when "{"
            tokens << current.strip unless current.strip.empty?
            tokens << char
            current = ""
            in_block = true
          when "}"
            tokens << current.strip unless current.strip.empty?
            tokens << char
            current = ""
            in_block = false
          when ";"
            tokens << current.strip unless current.strip.empty?
            tokens << char
            current = ""
          when ":"
            if in_block
              # Property:value separator
              tokens << current.strip unless current.strip.empty?
              tokens << char
              current = ""
            else
              # Pseudo-class, keep as part of selector
              current += char
            end
          when "\n", "\r"
            tokens << current.strip unless current.strip.empty?
            current = ""
          else
            current += char
          end
        end

        tokens << current.strip unless current.strip.empty?
        tokens.reject(&:empty?)
      end

      sig { params(tokens: T::Array[String], sheet: StyleSheet).void }
      def parse_rules(tokens, sheet)
        i = 0
        while i < tokens.length
          # Find selector
          selector = tokens[i]
          break unless selector
          i += 1

          # Expect {
          break unless tokens[i] == "{"
          i += 1

          # Parse properties until }
          props = {}
          while i < tokens.length && tokens[i] != "}"
            prop_name = tokens[i]
            i += 1

            break unless tokens[i] == ":"
            i += 1

            # Collect value tokens until ; or }
            value_tokens = []
            while i < tokens.length && tokens[i] != ";" && tokens[i] != "}"
              value_tokens << tokens[i]
              i += 1
            end

            # Skip ;
            i += 1 if tokens[i] == ";"

            prop_sym = prop_name.to_sym
            value = parse_value(prop_sym, value_tokens.join(" ").strip)
            props[prop_sym] = value
          end

          # Skip }
          i += 1 if tokens[i] == "}"

          sheet.add_rule(selector, **props) unless props.empty?
        end
      end

      sig { params(prop: Symbol, value_str: String).returns(T.untyped) }
      def parse_value(prop, value_str)
        case prop
        when :foreground, :background
          parse_color(value_str)
        when :width, :height, :min_width, :max_width, :min_height, :max_height
          value_str.to_i
        when :padding, :margin
          parse_spacing(value_str)
        when :bold, :italic, :underline
          value_str == "true"
        when :border, :text_align
          value_str.to_sym
        when :border_title
          value_str
        else
          value_str
        end
      end

      sig { params(value: String).returns(T.any(Symbol, Color::Rgb)) }
      def parse_color(value)
        if value.start_with?("#")
          parse_hex_color(value)
        elsif value.start_with?("rgb(")
          parse_rgb_color(value)
        else
          value.to_sym
        end
      end

      sig { params(hex: String).returns(Color::Rgb) }
      def parse_hex_color(hex)
        hex = hex.delete_prefix("#")
        r = hex[0..1].to_i(16)
        g = hex[2..3].to_i(16)
        b = hex[4..5].to_i(16)
        Color::Rgb.new(r: r, g: g, b: b)
      end

      sig { params(rgb: String).returns(Color::Rgb) }
      def parse_rgb_color(rgb)
        match = rgb.match(/rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)/)
        raise ParseError, "Invalid rgb color: #{rgb}" unless match

        Color::Rgb.new(
          r: match[1].to_i,
          g: match[2].to_i,
          b: match[3].to_i
        )
      end

      sig { params(value: String).returns(T::Array[Integer]) }
      def parse_spacing(value)
        parts = value.split.map(&:to_i)
        case parts.length
        when 1
          [parts[0], parts[0], parts[0], parts[0]]
        when 2
          [parts[0], parts[1], parts[0], parts[1]]
        when 4
          parts
        else
          raise ParseError, "Invalid spacing: #{value}"
        end
      end
    end
  end
end
