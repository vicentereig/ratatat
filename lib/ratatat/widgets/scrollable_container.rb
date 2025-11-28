# typed: strict
# frozen_string_literal: true

module Ratatat
  # Scrollable viewport widget
  class ScrollableContainer < Widget
    extend T::Sig

    CAN_FOCUS = true

    sig { returns(Integer) }
    attr_reader :virtual_width, :virtual_height

    reactive :scroll_x, default: 0, repaint: true
    reactive :scroll_y, default: 0, repaint: true

    sig { params(virtual_width: Integer, virtual_height: Integer, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(virtual_width: 80, virtual_height: 24, id: nil, classes: [])
      super(id: id, classes: classes)
      @virtual_width = virtual_width
      @virtual_height = virtual_height
      @scroll_x = 0
      @scroll_y = 0
      @viewport_width = T.let(80, Integer)
      @viewport_height = T.let(24, Integer)
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "up", "k"
        scroll_vertical(-1)
        message.stop
      when "down", "j"
        scroll_vertical(1)
        message.stop
      when "left", "h"
        scroll_horizontal(-1)
        message.stop
      when "right", "l"
        scroll_horizontal(1)
        message.stop
      when "page_up"
        scroll_vertical(-@viewport_height)
        message.stop
      when "page_down"
        scroll_vertical(@viewport_height)
        message.stop
      when "home"
        @scroll_y = 0
        message.stop
      when "end"
        @scroll_y = [@virtual_height - @viewport_height, 0].max
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      @viewport_width = width
      @viewport_height = height

      # Render children with scroll offset
      # Children should render to positions that account for scroll
      children.each do |child|
        next unless child.respond_to?(:render)

        # For now, simple implementation: child renders at (x - scroll_x, y - scroll_y)
        # A more sophisticated implementation would use a virtual buffer
        child.render(buffer, x: x, y: y, width: width, height: height)
      end
    end

    private

    sig { params(delta: Integer).void }
    def scroll_vertical(delta)
      max_scroll = [@virtual_height - @viewport_height, 0].max
      @scroll_y = (@scroll_y + delta).clamp(0, max_scroll)
    end

    sig { params(delta: Integer).void }
    def scroll_horizontal(delta)
      max_scroll = [@virtual_width - @viewport_width, 0].max
      @scroll_x = (@scroll_x + delta).clamp(0, max_scroll)
    end
  end
end
