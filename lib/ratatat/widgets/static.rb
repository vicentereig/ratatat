# typed: strict
# frozen_string_literal: true

module Ratatat
  # Simple text display widget
  class Static < Widget
    extend T::Sig

    reactive :text, default: "", repaint: true

    sig { params(text: String, id: T.nilable(String), classes: T::Array[String], styles: T.nilable(T::Hash[Symbol, T.untyped])).void }
    def initialize(text = "", id: nil, classes: [], styles: nil)
      super(id: id, classes: classes, styles: styles)
      @text = text
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      display_text = text[0, width] || ""
      buffer.put_string(x, y, display_text)
    end
  end
end
