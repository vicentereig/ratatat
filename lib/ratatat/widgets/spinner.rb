# typed: strict
# frozen_string_literal: true

module Ratatat
  # Animated loading spinner widget
  class Spinner < Widget
    extend T::Sig

    STYLES = T.let({
      dots: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"],
      line: ["-", "\\", "|", "/"],
      blocks: ["▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"],
      arrows: ["←", "↖", "↑", "↗", "→", "↘", "↓", "↙"],
      bounce: ["⠁", "⠂", "⠄", "⠂"],
      pulse: ["◐", "◓", "◑", "◒"]
    }.freeze, T::Hash[Symbol, T::Array[String]])

    DEFAULT_FRAMES = T.let(STYLES[:dots] || [], T::Array[String])

    sig { returns(T::Array[String]) }
    attr_reader :frames

    sig { returns(Float) }
    attr_reader :speed

    sig { returns(T.nilable(String)) }
    attr_reader :text

    reactive :frame_index, default: 0, repaint: true

    sig { params(frames: T.nilable(T::Array[String]), style: T.nilable(Symbol), speed: Float, text: T.nilable(String), id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(frames: nil, style: nil, speed: 0.1, text: nil, id: nil, classes: [])
      super(id: id, classes: classes)
      @frames = T.let(
        frames || (style ? (STYLES[style] || DEFAULT_FRAMES) : DEFAULT_FRAMES),
        T::Array[String]
      )
      @speed = speed
      @text = text
      @frame_index = 0
      @spinning = T.let(false, T::Boolean)
      @timer_id = T.let(nil, T.nilable(Integer))
    end

    sig { returns(String) }
    def current_frame
      @frames[@frame_index] || @frames.first || " "
    end

    sig { void }
    def advance
      @frame_index = (@frame_index + 1) % @frames.length
    end

    sig { returns(T::Boolean) }
    def spinning?
      @spinning
    end

    sig { void }
    def start
      return if @spinning

      @spinning = true
      app_instance = app
      return unless app_instance

      @timer_id = app_instance.set_interval(@speed) { advance }
    end

    sig { void }
    def stop
      return unless @spinning

      @spinning = false
      app_instance = app
      return unless app_instance || @timer_id.nil?

      app_instance&.cancel_timer(T.must(@timer_id)) if @timer_id
      @timer_id = nil
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      output = if @text
                 "#{current_frame} #{@text}"
               else
                 current_frame
               end
      buffer.put_string(x, y, output[0, width] || "")
    end
  end
end
