# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::Binding do
  describe "creation" do
    it "accepts key, action, description" do
      binding = Ratatat::Binding.new("q", "quit", "Quit application")
      expect(binding.key).to eq("q")
      expect(binding.action).to eq("quit")
      expect(binding.description).to eq("Quit application")
    end

    it "defaults show to true" do
      binding = Ratatat::Binding.new("q", "quit", "Quit")
      expect(binding.show).to eq(true)
    end

    it "defaults priority to false" do
      binding = Ratatat::Binding.new("q", "quit", "Quit")
      expect(binding.priority).to eq(false)
    end

    it "accepts show and priority options" do
      binding = Ratatat::Binding.new("q", "quit", "Quit", show: false, priority: true)
      expect(binding.show).to eq(false)
      expect(binding.priority).to eq(true)
    end
  end

  describe "#matches?" do
    it "matches simple key" do
      binding = Ratatat::Binding.new("q", "quit", "Quit")
      expect(binding.matches?("q", Set.new)).to eq(true)
      expect(binding.matches?("x", Set.new)).to eq(false)
    end

    it "matches symbol key" do
      binding = Ratatat::Binding.new("up", "move_up", "Move up")
      expect(binding.matches?(:up, Set.new)).to eq(true)
    end

    it "matches ctrl modifier" do
      binding = Ratatat::Binding.new("ctrl+c", "cancel", "Cancel")
      expect(binding.matches?(:c, Set[:ctrl])).to eq(true)
      expect(binding.matches?(:c, Set.new)).to eq(false)
    end

    it "matches multiple keys" do
      binding = Ratatat::Binding.new("up,k", "move_up", "Move up")
      expect(binding.matches?(:up, Set.new)).to eq(true)
      expect(binding.matches?("k", Set.new)).to eq(true)
      expect(binding.matches?("j", Set.new)).to eq(false)
    end
  end
end

RSpec.describe "Widget BINDINGS" do
  it "calls action method when key matches" do
    widget_class = Class.new(Ratatat::Widget) do
      attr_reader :quit_called

      def action_quit
        @quit_called = true
      end
    end
    widget_class.const_set(:CAN_FOCUS, true)
    widget_class.const_set(:BINDINGS, [Ratatat::Binding.new("q", "quit", "Quit")])

    app = Ratatat::App.new
    widget = widget_class.new
    app.mount(widget)
    widget.focus

    app.post(Ratatat::Key.new(sender: app, key: "q"))
    app.process_messages

    expect(widget.quit_called).to eq(true)
  end

  it "bubbles to parent if no binding matches" do
    parent_class = Class.new(Ratatat::Widget) do
      attr_reader :quit_called

      def action_quit
        @quit_called = true
      end
    end
    parent_class.const_set(:BINDINGS, [Ratatat::Binding.new("q", "quit", "Quit")])

    child_class = Class.new(Ratatat::Widget)
    child_class.const_set(:CAN_FOCUS, true)

    app = Ratatat::App.new
    parent = parent_class.new
    child = child_class.new
    parent.mount(child)
    app.mount(parent)
    child.focus

    app.post(Ratatat::Key.new(sender: app, key: "q"))
    app.process_messages

    expect(parent.quit_called).to eq(true)
  end

  it "stops bubbling after binding handled" do
    parent_class = Class.new(Ratatat::Widget) do
      attr_reader :called

      def action_parent_quit
        @called = true
      end
    end
    parent_class.const_set(:BINDINGS, [Ratatat::Binding.new("q", "parent_quit", "Quit")])

    child_class = Class.new(Ratatat::Widget) do
      attr_reader :called

      def action_child_quit
        @called = true
      end
    end
    child_class.const_set(:CAN_FOCUS, true)
    child_class.const_set(:BINDINGS, [Ratatat::Binding.new("q", "child_quit", "Quit")])

    app = Ratatat::App.new
    parent = parent_class.new
    child = child_class.new
    parent.mount(child)
    app.mount(parent)
    child.focus

    app.post(Ratatat::Key.new(sender: app, key: "q"))
    app.process_messages

    expect(child.called).to eq(true)
    expect(parent.called).to be_nil
  end

  it "supports array shorthand for bindings" do
    widget_class = Class.new(Ratatat::Widget) do
      attr_reader :quit_called

      def action_quit
        @quit_called = true
      end
    end
    widget_class.const_set(:CAN_FOCUS, true)
    widget_class.const_set(:BINDINGS, [["q", "quit", "Quit"]])

    app = Ratatat::App.new
    widget = widget_class.new
    app.mount(widget)
    widget.focus

    app.post(Ratatat::Key.new(sender: app, key: "q"))
    app.process_messages

    expect(widget.quit_called).to eq(true)
  end
end

RSpec.describe "App default bindings" do
  it "handles Tab for focus_next" do
    focusable_class = Class.new(Ratatat::Widget)
    focusable_class.const_set(:CAN_FOCUS, true)

    app = Ratatat::App.new
    w1 = focusable_class.new(id: "w1")
    w2 = focusable_class.new(id: "w2")
    app.mount(w1, w2)
    w1.focus

    app.post(Ratatat::Key.new(sender: app, key: :tab))
    app.process_messages

    expect(app.focused).to eq(w2)
  end

  it "handles Shift+Tab for focus_previous" do
    focusable_class = Class.new(Ratatat::Widget)
    focusable_class.const_set(:CAN_FOCUS, true)

    app = Ratatat::App.new
    w1 = focusable_class.new(id: "w1")
    w2 = focusable_class.new(id: "w2")
    app.mount(w1, w2)
    w2.focus

    app.post(Ratatat::Key.new(sender: app, key: :shift_tab))
    app.process_messages

    expect(app.focused).to eq(w1)
  end
end
