# typed: strict
# frozen_string_literal: true

module Ratatat
  # Toast notification widget
  class Toast < Widget
    extend T::Sig

    ICONS = T.let({
      info: "ℹ",
      success: "✓",
      warning: "⚠",
      error: "✗"
    }.freeze, T::Hash[Symbol, String])

    sig { returns(String) }
    attr_reader :message

    sig { returns(Symbol) }
    attr_reader :severity

    sig { returns(Float) }
    attr_reader :duration

    reactive :visible, default: true, repaint: true

    sig { params(message: String, severity: Symbol, duration: Float, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(message:, severity: :info, duration: 5.0, id: nil, classes: [])
      super(id: id, classes: classes)
      @message = message
      @severity = severity
      @duration = duration
      @visible = true
    end

    sig { void }
    def show
      @visible = true
    end

    sig { void }
    def hide
      @visible = false
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      return unless @visible

      icon = ICONS[@severity] || ICONS[:info]
      text = "#{icon} #{@message}"
      buffer.put_string(x, y, text[0, width] || "")
    end
  end
end
