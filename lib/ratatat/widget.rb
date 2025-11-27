# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Ratatat
  class QueryError < StandardError; end

  # Base class for all widgets in the UI tree.
  class Widget
    extend T::Sig

    CAN_FOCUS = false

    sig { returns(T.nilable(String)) }
    attr_reader :id

    sig { returns(T::Set[String]) }
    attr_reader :classes

    sig { returns(T.nilable(Widget)) }
    attr_reader :parent

    sig { returns(T::Array[Widget]) }
    attr_reader :children

    sig { params(id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(id: nil, classes: [])
      @id = id
      @classes = T.let(classes.to_set, T::Set[String])
      @parent = T.let(nil, T.nilable(Widget))
      @children = T.let([], T::Array[Widget])
      @has_focus = T.let(false, T::Boolean)
    end

    # Add children to this widget
    sig { params(widgets: Widget).returns(T.self_type) }
    def mount(*widgets)
      widgets.each do |widget|
        widget.instance_variable_set(:@parent, self)
        @children << widget
        trigger_mount(widget)
      end
      self
    end

    # Remove this widget from its parent
    sig { void }
    def remove
      return unless @parent

      @parent.children.delete(self)
      @parent = nil
      trigger_unmount(self)
    end

    # Get ancestor chain (parent, grandparent, ...)
    sig { returns(T::Array[Widget]) }
    def ancestors
      result = []
      current = @parent
      while current
        result << current
        current = current.parent
      end
      result
    end

    # Focus management
    sig { returns(T::Boolean) }
    def can_focus?
      # Search class hierarchy for CAN_FOCUS
      klass = T.let(self.class, T.nilable(T::Class[T.anything]))
      while klass
        return klass.const_get(:CAN_FOCUS, false) if klass.const_defined?(:CAN_FOCUS, false)
        klass = klass.superclass
      end
      false
    end

    sig { returns(T::Boolean) }
    def has_focus?
      @has_focus
    end

    # Request focus for this widget
    sig { void }
    def focus
      return unless can_focus?
      app&.set_focus(self)
    end

    # Remove focus from this widget
    sig { void }
    def blur
      return unless @has_focus
      app&.set_focus(nil)
    end

    # Find the root App
    sig { returns(T.nilable(App)) }
    def app
      current = T.let(self, T.nilable(Widget))
      while current
        return T.cast(current, App) if current.is_a?(App)
        current = current.parent
      end
      nil
    end

    # Dispatch a message to this widget and bubble up
    sig { params(message: Message).void }
    def dispatch(message)
      handler = handler_for(message)
      send(handler, message) if handler && respond_to?(handler)

      return if message.stopped? || !message.bubble
      @parent&.dispatch(message)
    end

    # Query descendants by selector
    sig { params(selector: T.any(String, T::Class[Widget])).returns(T::Array[Widget]) }
    def query(selector)
      results = []
      walk_descendants { |w| results << w if matches?(w, selector) }
      results
    end

    sig { params(selector: T.any(String, T::Class[Widget])).returns(T.nilable(Widget)) }
    def query_one(selector)
      query(selector).first
    end

    sig { params(selector: T.any(String, T::Class[Widget])).returns(Widget) }
    def query_one!(selector)
      query_one(selector) || raise(QueryError, "No widget matching: #{selector}")
    end

    private

    sig { params(message: Message).returns(T.nilable(Symbol)) }
    def handler_for(message)
      # Key -> :on_key, Resize -> :on_resize
      name = message.class.name&.split("::")&.last&.downcase
      return nil unless name
      :"on_#{name}"
    end

    sig { params(block: T.proc.params(widget: Widget).void).void }
    def walk_descendants(&block)
      @children.each do |child|
        block.call(child)
        child.send(:walk_descendants, &block)
      end
    end

    sig { params(widget: Widget, selector: T.any(String, T::Class[Widget])).returns(T::Boolean) }
    def matches?(widget, selector)
      case selector
      when String
        if selector.start_with?("#")
          widget.id == selector[1..]
        elsif selector.start_with?(".")
          widget.classes.include?(selector[1..])
        else
          false
        end
      when Class
        widget.is_a?(selector)
      else
        false
      end
    end

    sig { params(widget: Widget).void }
    def trigger_mount(widget)
      # Only trigger if we're connected to an App
      return unless widget.app

      widget.on_mount if widget.respond_to?(:on_mount)
      widget.children.each { |child| trigger_mount(child) }
    end

    sig { params(widget: Widget).void }
    def trigger_unmount(widget)
      widget.children.each { |child| trigger_unmount(child) }
      widget.on_unmount if widget.respond_to?(:on_unmount)
    end
  end
end
