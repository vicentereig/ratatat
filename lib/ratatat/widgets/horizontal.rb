# typed: strict
# frozen_string_literal: true

module Ratatat
  # Horizontal flexbox-like layout widget
  class Horizontal < Widget
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :gap

    sig { returns(T.nilable(T::Array[Float])) }
    attr_reader :ratios

    sig { params(gap: Integer, ratios: T.nilable(T::Array[Float]), id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(gap: 0, ratios: nil, id: nil, classes: [])
      super(id: id, classes: classes)
      @gap = gap
      @ratios = ratios
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return if children.empty?

      total_gap = @gap * (children.length - 1)
      available_width = width - total_gap

      widths = calculate_widths(available_width)
      current_x = x

      children.each_with_index do |child, i|
        child_width = widths[i] || 0
        child.render(buffer, x: current_x, y: y, width: child_width, height: height) if child.respond_to?(:render)
        current_x += child_width + @gap
      end
    end

    private

    sig { params(available_width: Integer).returns(T::Array[Integer]) }
    def calculate_widths(available_width)
      if @ratios && @ratios.length == children.length
        @ratios.map { |r| (available_width * r).to_i }
      else
        # Equal distribution
        child_width = available_width / children.length
        Array.new(children.length, child_width)
      end
    end
  end
end
