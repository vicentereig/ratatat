# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Provides the reactive property DSL for widgets
  module Reactive
    extend T::Sig

    # Class methods added when Reactive is extended
    module ClassMethods
      extend T::Sig

      # Define a reactive property
      sig { params(name: Symbol, default: T.untyped, repaint: T::Boolean).void }
      def reactive(name, default: nil, repaint: true)
        # Store reactive metadata
        @_reactives ||= {}
        @_reactives[name] = { default: default, repaint: repaint }

        # Define getter
        define_method(name) do
          ivar = :"@#{name}"
          if instance_variable_defined?(ivar)
            instance_variable_get(ivar)
          else
            self.class.reactive_default(name)
          end
        end

        # Define setter
        define_method(:"#{name}=") do |value|
          ivar = :"@#{name}"
          old_value = send(name)

          # Run validator if defined
          validator = :"validate_#{name}"
          value = send(validator, value) if respond_to?(validator, true)

          # Skip if unchanged
          return if old_value == value

          # Store new value
          instance_variable_set(ivar, value)

          # Call watcher if defined
          watcher = :"watch_#{name}"
          send(watcher, old_value, value) if respond_to?(watcher, true)

          # Trigger repaint if configured
          if self.class.reactive_repaint?(name) && respond_to?(:refresh, true)
            send(:refresh)
          end
        end
      end

      sig { params(name: Symbol).returns(T.untyped) }
      def reactive_default(name)
        @_reactives&.dig(name, :default)
      end

      sig { params(name: Symbol).returns(T::Boolean) }
      def reactive_repaint?(name)
        @_reactives&.dig(name, :repaint) != false
      end

      sig { returns(T::Hash[Symbol, T::Hash[Symbol, T.untyped]]) }
      def reactives
        @_reactives || {}
      end
    end

    sig { params(base: T::Class[T.anything]).void }
    def self.extended(base)
      base.extend(ClassMethods)
    end
  end
end
