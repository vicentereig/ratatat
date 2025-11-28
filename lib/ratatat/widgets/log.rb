# typed: strict
# frozen_string_literal: true

module Ratatat
  # Scrolling log viewer widget
  class Log < Widget
    extend T::Sig

    CAN_FOCUS = true

    sig { returns(T::Array[String]) }
    attr_reader :lines

    sig { returns(T::Boolean) }
    attr_accessor :auto_scroll

    sig { returns(T.nilable(Integer)) }
    attr_reader :max_lines

    reactive :scroll_offset, default: 0, repaint: true

    sig { params(max_lines: T.nilable(Integer), auto_scroll: T::Boolean, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(max_lines: nil, auto_scroll: true, id: nil, classes: [])
      super(id: id, classes: classes)
      @lines = T.let([], T::Array[String])
      @max_lines = max_lines
      @auto_scroll = auto_scroll
      @scroll_offset = 0
      @view_height = T.let(5, Integer)
    end

    sig { params(text: String).void }
    def write(text)
      @lines << text
      @lines.shift if @max_lines && @lines.length > @max_lines
      @scroll_offset = [0, @lines.length - @view_height].max if @auto_scroll
      refresh
    end

    alias write_line write

    sig { void }
    def clear
      @lines.clear
      @scroll_offset = 0
      refresh
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "up", "k"
        scroll(-1)
        message.stop
      when "down", "j"
        scroll(1)
        message.stop
      when "page_up"
        scroll(-@view_height)
        message.stop
      when "page_down"
        scroll(@view_height)
        message.stop
      when "home"
        @scroll_offset = 0
        @auto_scroll = false
        message.stop
      when "end"
        @scroll_offset = [0, @lines.length - @view_height].max
        @auto_scroll = true
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      @view_height = height

      # Recalculate scroll position for auto-scroll based on actual view height
      @scroll_offset = [0, @lines.length - @view_height].max if @auto_scroll

      visible_lines = @lines[@scroll_offset, height] || []
      visible_lines.each_with_index do |line, i|
        buffer.put_string(x, y + i, line[0, width] || "")
      end
    end

    private

    sig { params(delta: Integer).void }
    def scroll(delta)
      max_offset = [0, @lines.length - @view_height].max
      @scroll_offset = (@scroll_offset + delta).clamp(0, max_offset)
      @auto_scroll = false if delta < 0
    end
  end
end
