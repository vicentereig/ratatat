# typed: strict
# frozen_string_literal: true

module Ratatat
  # Generic container widget
  class Container < Widget
    extend T::Sig

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      # Default: render first child with full size
      return if children.empty?

      child = children.first
      child.render(buffer, x: x, y: y, width: width, height: height) if child.respond_to?(:render)
    end
  end

  # Horizontal layout - children side by side
  class Horizontal < Widget
    extend T::Sig

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return if children.empty?

      child_width = width / children.length
      children.each_with_index do |child, i|
        child_x = x + (i * child_width)
        child.render(buffer, x: child_x, y: y, width: child_width, height: height) if child.respond_to?(:render)
      end
    end
  end

  # Vertical layout - children stacked
  class Vertical < Widget
    extend T::Sig

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return if children.empty?

      child_height = height / children.length
      children.each_with_index do |child, i|
        child_y = y + (i * child_height)
        child.render(buffer, x: x, y: child_y, width: width, height: child_height) if child.respond_to?(:render)
      end
    end
  end
end
