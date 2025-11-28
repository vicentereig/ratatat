# typed: strict
# frozen_string_literal: true

module Ratatat
  # Chainable query object for finding widgets in the tree
  class DOMQuery
    extend T::Sig
    include Enumerable

    sig { params(widgets: T::Array[Widget]).void }
    def initialize(widgets)
      @widgets = widgets
    end

    sig { params(selector: String).returns(DOMQuery) }
    def filter(selector)
      DOMQuery.new(@widgets.select { |w| matches?(w, selector) })
    end

    sig { params(selector: String).returns(DOMQuery) }
    def exclude(selector)
      DOMQuery.new(@widgets.reject { |w| matches?(w, selector) })
    end

    sig { returns(T.nilable(Widget)) }
    def first
      @widgets.first
    end

    sig { returns(T.nilable(Widget)) }
    def last
      @widgets.last
    end

    sig { returns(T::Array[Widget]) }
    def to_a
      @widgets.dup
    end

    sig { override.params(block: T.proc.params(arg0: Widget).void).returns(T.untyped) }
    def each(&block)
      @widgets.each(&block)
    end

    sig { returns(Integer) }
    def count
      @widgets.length
    end

    sig { returns(T::Boolean) }
    def empty?
      @widgets.empty?
    end

    # Bulk operations

    # Add a class to all matched widgets
    sig { params(name: String).returns(DOMQuery) }
    def add_class(name)
      @widgets.each { |w| w.add_class(name) }
      self
    end

    # Remove a class from all matched widgets
    sig { params(name: String).returns(DOMQuery) }
    def remove_class(name)
      @widgets.each { |w| w.remove_class(name) }
      self
    end

    # Toggle a class on all matched widgets
    sig { params(name: String).returns(DOMQuery) }
    def toggle_class(name)
      @widgets.each { |w| w.toggle_class(name) }
      self
    end

    # Refresh all matched widgets
    sig { returns(DOMQuery) }
    def refresh
      @widgets.each(&:refresh)
      self
    end

    # Remove all matched widgets from their parents
    sig { returns(DOMQuery) }
    def remove
      @widgets.each(&:remove)
      self
    end

    # Focus the first matched widget
    sig { returns(T.nilable(Widget)) }
    def focus
      first&.focus
      first
    end

    # Set styles on all matched widgets
    sig { params(props: T.untyped).returns(DOMQuery) }
    def set_styles(**props)
      @widgets.each do |w|
        props.each do |key, value|
          setter = :"#{key}="
          w.styles.send(setter, value) if w.styles.respond_to?(setter)
        end
      end
      self
    end

    private

    sig { params(widget: Widget, selector: String).returns(T::Boolean) }
    def matches?(widget, selector)
      if selector.start_with?("#")
        widget.id == selector[1..]
      elsif selector.start_with?(".")
        widget.classes.include?(selector[1..])
      else
        widget.class.name&.split("::")&.last == selector
      end
    end
  end
end
