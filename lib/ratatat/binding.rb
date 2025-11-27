# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  # Represents a key binding that maps keys to actions.
  class Binding
    extend T::Sig

    sig { returns(String) }
    attr_reader :key, :action, :description

    sig { returns(T::Boolean) }
    attr_reader :show, :priority

    sig { params(key: String, action: String, description: String, show: T::Boolean, priority: T::Boolean).void }
    def initialize(key, action, description, show: true, priority: false)
      @key = key
      @action = action
      @description = description
      @show = show
      @priority = priority
      @parsed_keys = T.let(parse_keys(key), T::Array[ParsedKey])
    end

    # Check if this binding matches the given key and modifiers
    sig { params(key: T.any(Symbol, String), modifiers: T::Set[Symbol]).returns(T::Boolean) }
    def matches?(key, modifiers)
      key_str = key.to_s
      @parsed_keys.any? { |pk| pk.matches?(key_str, modifiers) }
    end

    private

    # A parsed key with optional modifiers
    class ParsedKey
      extend T::Sig

      sig { returns(String) }
      attr_reader :key

      sig { returns(T::Set[Symbol]) }
      attr_reader :modifiers

      sig { params(key: String, modifiers: T::Set[Symbol]).void }
      def initialize(key, modifiers)
        @key = key
        @modifiers = modifiers
      end

      sig { params(key: String, modifiers: T::Set[Symbol]).returns(T::Boolean) }
      def matches?(key, modifiers)
        @key == key && @modifiers == modifiers
      end
    end

    sig { params(key_spec: String).returns(T::Array[ParsedKey]) }
    def parse_keys(key_spec)
      key_spec.split(",").map { |k| parse_single_key(k.strip) }
    end

    sig { params(key_str: String).returns(ParsedKey) }
    def parse_single_key(key_str)
      parts = key_str.split("+")
      if parts.length == 1
        ParsedKey.new(parts[0], Set.new)
      else
        modifiers = parts[0..-2].map(&:to_sym).to_set
        ParsedKey.new(T.must(parts.last), modifiers)
      end
    end
  end
end
