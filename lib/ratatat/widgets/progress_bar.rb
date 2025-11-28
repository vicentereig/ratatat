# typed: strict
# frozen_string_literal: true

module Ratatat
  # Progress bar widget
  class ProgressBar < Widget
    extend T::Sig

    reactive :total, default: 100.0, repaint: true
    reactive :completed, default: 0.0, repaint: true

    sig { params(progress: T.nilable(Float), total: Float, completed: Float, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(progress: nil, total: 100.0, completed: 0.0, id: nil, classes: [])
      super(id: id, classes: classes)
      @total = total
      @completed = completed
      self.progress = progress if progress
    end

    sig { returns(Float) }
    def progress
      return 0.0 if total <= 0

      (completed / total).clamp(0.0, 1.0)
    end

    sig { params(value: Float).void }
    def progress=(value)
      self.completed = (value.clamp(0.0, 1.0) * total)
    end

    sig { params(amount: Float).void }
    def advance(amount = 1.0)
      self.completed = completed + amount
    end

    def validate_completed(value)
      value.clamp(0.0, total)
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      filled = (progress * width).round
      empty = width - filled

      bar = "█" * filled + "░" * empty
      buffer.put_string(x, y, bar)
    end
  end

  # Spinning indicator widget
  class Spinner < Widget
    extend T::Sig

    FRAMES = T.let(["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"].freeze, T::Array[String])

    reactive :frame, default: 0, repaint: true

    sig { params(id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(id: nil, classes: [])
      super(id: id, classes: classes)
      @frame = 0
    end

    sig { returns(String) }
    def current_frame
      FRAMES[@frame % FRAMES.length] || FRAMES.first || ""
    end

    sig { void }
    def advance
      self.frame = (@frame + 1) % FRAMES.length
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      buffer.put_string(x, y, current_frame)
    end
  end
end
