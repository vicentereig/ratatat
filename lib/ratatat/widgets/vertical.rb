# typed: strict
# frozen_string_literal: true

module Ratatat
  # Vertical flexbox-like layout widget
  class Vertical < Widget
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
      available_height = height - total_gap

      heights = calculate_heights(available_height)
      current_y = y

      children.each_with_index do |child, i|
        child_height = heights[i] || 0
        child.render(buffer, x: x, y: current_y, width: width, height: child_height) if child.respond_to?(:render)
        current_y += child_height + @gap
      end
    end

    private

    sig { params(available_height: Integer).returns(T::Array[Integer]) }
    def calculate_heights(available_height)
      if @ratios && @ratios.length == children.length
        @ratios.map { |r| (available_height * r).to_i }
      else
        # Equal distribution
        child_height = available_height / children.length
        Array.new(children.length, child_height)
      end
    end
  end
end
