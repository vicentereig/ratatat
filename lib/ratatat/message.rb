# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Base class for all messages in the event system.
  # Messages flow up the widget tree (bubbling) unless stopped.
  class Message
    extend T::Sig

    sig { returns(T.untyped) }
    attr_reader :sender

    sig { returns(Time) }
    attr_reader :time

    sig { returns(T::Boolean) }
    attr_accessor :bubble

    sig { params(sender: T.untyped, bubble: T::Boolean).void }
    def initialize(sender:, bubble: true)
      @sender = sender
      @time = T.let(Time.now, Time)
      @bubble = bubble
      @stopped = T.let(false, T::Boolean)
      @prevented = T.let(false, T::Boolean)
    end

    sig { void }
    def stop
      @stopped = true
    end

    sig { returns(T::Boolean) }
    def stopped?
      @stopped
    end

    sig { void }
    def prevent_default
      @prevented = true
    end

    sig { returns(T::Boolean) }
    def prevented?
      @prevented
    end
  end

  # Keyboard input message
  class Key < Message
    extend T::Sig

    sig { returns(T.any(Symbol, String)) }
    attr_reader :key

    sig { returns(T::Set[Symbol]) }
    attr_reader :modifiers

    sig { params(sender: T.untyped, key: T.any(Symbol, String), modifiers: T::Set[Symbol], bubble: T::Boolean).void }
    def initialize(sender:, key:, modifiers: Set.new, bubble: true)
      super(sender: sender, bubble: bubble)
      @key = key
      @modifiers = modifiers
    end

    sig { returns(T::Boolean) }
    def ctrl? = @modifiers.include?(:ctrl)

    sig { returns(T::Boolean) }
    def alt? = @modifiers.include?(:alt)

    sig { returns(T::Boolean) }
    def shift? = @modifiers.include?(:shift)
  end

  # Terminal resize message
  class Resize < Message
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :width, :height

    sig { params(sender: T.untyped, width: Integer, height: Integer, bubble: T::Boolean).void }
    def initialize(sender:, width:, height:, bubble: true)
      super(sender: sender, bubble: bubble)
      @width = width
      @height = height
    end
  end

  # Application quit message
  class Quit < Message
    extend T::Sig

    sig { params(sender: T.untyped).void }
    def initialize(sender:)
      super(sender: sender, bubble: false)
    end
  end

  # Widget gained focus
  class Focus < Message
    extend T::Sig

    sig { params(sender: T.untyped).void }
    def initialize(sender:)
      super(sender: sender, bubble: false)
    end
  end

  # Widget lost focus
  class Blur < Message
    extend T::Sig

    sig { params(sender: T.untyped).void }
    def initialize(sender:)
      super(sender: sender, bubble: false)
    end
  end

  # Worker namespace for background task messages
  module Worker
    # Worker completed message
    class Done < Message
      extend T::Sig

      sig { returns(Symbol) }
      attr_reader :name

      sig { returns(T.untyped) }
      attr_reader :result

      sig { returns(T.nilable(Exception)) }
      attr_reader :error

      sig { params(sender: T.untyped, name: Symbol, result: T.untyped, error: T.nilable(Exception)).void }
      def initialize(sender:, name:, result: nil, error: nil)
        super(sender: sender, bubble: true)
        @name = name
        @result = result
        @error = error
      end
    end
  end
end
