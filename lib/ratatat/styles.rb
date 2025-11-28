# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Style properties for widgets
  class Styles
    extend T::Sig

    PROPERTIES = T.let(%i[
      foreground background
      width height min_width max_width min_height max_height
      padding margin
      bold italic underline
      border border_title
      text_align
    ].freeze, T::Array[Symbol])

    sig { returns(T.nilable(T.any(Symbol, Color::Rgb, Color::Indexed))) }
    attr_accessor :foreground, :background

    sig { returns(T.nilable(Integer)) }
    attr_accessor :width, :height, :min_width, :max_width, :min_height, :max_height

    sig { returns(T.nilable(T::Array[Integer])) }
    attr_accessor :padding, :margin

    sig { returns(T.nilable(T::Boolean)) }
    attr_accessor :bold, :italic, :underline

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :border, :text_align

    sig { returns(T.nilable(String)) }
    attr_accessor :border_title

    sig { params(props: T.untyped).void }
    def initialize(**props)
      props.each do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
    end

    sig { params(other: Styles).returns(Styles) }
    def merge(other)
      result = Styles.new
      PROPERTIES.each do |prop|
        my_value = send(prop)
        other_value = other.send(prop)
        result.send(:"#{prop}=", other_value.nil? ? my_value : other_value)
      end
      result
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_h
      PROPERTIES.each_with_object({}) do |prop, hash|
        value = send(prop)
        hash[prop] = value unless value.nil?
      end
    end
  end

  # Manages style rules and computes styles for widgets
  class StyleSheet
    extend T::Sig

    Rule = T.type_alias { { selector: String, styles: Styles, specificity: Integer } }

    sig { void }
    def initialize
      @rules = T.let([], T::Array[Rule])
    end

    sig { params(selector: String, props: T.untyped).void }
    def add_rule(selector, **props)
      @rules << {
        selector: selector,
        styles: Styles.new(**props),
        specificity: compute_specificity(selector)
      }
    end

    sig { params(widget: Widget).returns(Styles) }
    def compute(widget)
      matching = @rules.select { |rule| matches?(widget, rule[:selector]) }
      sorted = matching.sort_by { |rule| rule[:specificity] }

      result = Styles.new
      sorted.each do |rule|
        result = result.merge(rule[:styles])
      end
      result
    end

    private

    sig { params(selector: String).returns(Integer) }
    def compute_specificity(selector)
      # Handle combinator selectors
      parts = parse_combinator_parts(selector)
      return parts.sum { |part| compute_simple_specificity(part[:selector]) }
    end

    sig { params(selector: String).returns(Integer) }
    def compute_simple_specificity(selector)
      # Strip :not() for specificity calculation
      selector = selector.gsub(/:not\([^)]+\)/, "")

      # Parse compound selector parts
      parts = parse_compound_selector(selector)
      specificity = 0

      parts.each do |part|
        if part.start_with?("#")
          specificity += 100
        elsif part.start_with?(".")
          specificity += 10
        else
          specificity += 1
        end
      end

      # Add pseudo-class specificity
      specificity += 10 if selector.include?(":")
      specificity
    end

    sig { params(selector: String).returns(T::Array[{ selector: String, combinator: T.nilable(Symbol) }]) }
    def parse_combinator_parts(selector)
      parts = T.let([], T::Array[{ selector: String, combinator: T.nilable(Symbol) }])

      # Split by child combinator first
      if selector.include?(" > ")
        segments = selector.split(" > ")
        segments.each_with_index do |seg, i|
          # Each segment might have descendant selectors
          if seg.include?(" ")
            sub_parts = seg.strip.split(/\s+/)
            sub_parts.each_with_index do |sub, j|
              combinator = j < sub_parts.length - 1 ? :descendant : (i < segments.length - 1 ? :child : nil)
              parts << { selector: sub, combinator: combinator }
            end
          else
            parts << { selector: seg.strip, combinator: i < segments.length - 1 ? :child : nil }
          end
        end
      elsif selector.include?(" ")
        # Only descendant combinators
        segments = selector.split(/\s+/)
        segments.each_with_index do |seg, i|
          parts << { selector: seg, combinator: i < segments.length - 1 ? :descendant : nil }
        end
      else
        parts << { selector: selector, combinator: nil }
      end

      parts
    end

    sig { params(selector: String).returns(T::Array[String]) }
    def parse_compound_selector(selector)
      # Remove pseudo-classes for parsing
      selector = selector.gsub(/:[a-z-]+(\([^)]*\))?/, "")

      parts = T.let([], T::Array[String])

      # Extract ID
      if selector.include?("#")
        id_match = selector.match(/#([a-zA-Z0-9_-]+)/)
        parts << "##{id_match[1]}" if id_match
      end

      # Extract classes
      selector.scan(/\.([a-zA-Z0-9_-]+)/).each do |match|
        parts << ".#{match[0]}"
      end

      # Extract type (must be at start, before # or .)
      type_match = selector.match(/^([a-zA-Z][a-zA-Z0-9_]*)/)
      if type_match && !type_match[1].nil?
        type_name = T.must(type_match[1])
        parts.unshift(type_name) unless type_name.empty?
      end

      parts
    end

    sig { params(widget: Widget, selector: String).returns(T::Boolean) }
    def matches?(widget, selector)
      parts = parse_combinator_parts(selector)

      # Single selector (no combinators)
      return matches_simple?(widget, parts[0][:selector]) if parts.length == 1

      # Combinator selector - check from right to left
      current = widget
      (parts.length - 1).downto(0) do |i|
        part = parts[i]
        return false unless matches_simple?(current, part[:selector])

        # Move up the tree based on combinator
        if i > 0
          prev_combinator = parts[i - 1][:combinator]
          case prev_combinator
          when :child
            current = current.parent
            return false if current.nil?
          when :descendant
            # Find any ancestor matching the next selector
            found = false
            ancestor = current.parent
            while ancestor
              if matches_simple?(ancestor, parts[i - 1][:selector])
                current = ancestor
                found = true
                break
              end
              ancestor = ancestor.parent
            end
            return false unless found
            next # Skip the normal iteration since we handled it
          end
        end
      end

      true
    end

    sig { params(widget: Widget, selector: String).returns(T::Boolean) }
    def matches_simple?(widget, selector)
      # Handle :not() pseudo-class
      not_match = selector.match(/:not\(([^)]+)\)/)
      if not_match
        not_selector = not_match[1]
        return false if matches_simple?(widget, not_selector)
        selector = selector.gsub(/:not\([^)]+\)/, "")
      end

      # Parse base and pseudo-class
      base, pseudo = parse_simple_selector(selector)

      # Check compound selector
      base_matches = matches_compound?(widget, base)
      return false unless base_matches

      # Check pseudo-class if present
      return true unless pseudo

      case pseudo
      when "focus"
        widget.has_focus?
      when "disabled"
        widget.disabled == true
      when "hover"
        widget.hover == true
      else
        false
      end
    end

    sig { params(selector: String).returns([String, T.nilable(String)]) }
    def parse_simple_selector(selector)
      # Match pseudo-class but not :not()
      if selector.match?(/:[a-z]+$/)
        parts = selector.split(":")
        [parts[0..-2].join(":"), parts.last]
      else
        [selector, nil]
      end
    end

    sig { params(widget: Widget, selector: String).returns(T::Boolean) }
    def matches_compound?(widget, selector)
      return true if selector.empty?

      parts = parse_compound_selector(selector)
      return true if parts.empty?

      parts.all? do |part|
        if part.start_with?("#")
          widget.id == part[1..]
        elsif part.start_with?(".")
          widget.classes.include?(part[1..])
        else
          # Type selector
          widget.class.name&.split("::")&.last == part
        end
      end
    end
  end
end
