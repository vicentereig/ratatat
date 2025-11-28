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
      # ID = 100, class = 10, type = 1
      if selector.start_with?("#")
        100
      elsif selector.start_with?(".")
        10
      else
        1
      end
    end

    sig { params(widget: Widget, selector: String).returns(T::Boolean) }
    def matches?(widget, selector)
      if selector.start_with?("#")
        widget.id == selector[1..]
      elsif selector.start_with?(".")
        widget.classes.include?(selector[1..])
      else
        # Type selector - match class name
        widget.class.name&.split("::")&.last == selector
      end
    end
  end
end
