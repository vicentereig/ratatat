# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::Widget do
  describe "identity" do
    it "has optional id" do
      widget = Ratatat::Widget.new(id: "sidebar")
      expect(widget.id).to eq("sidebar")
    end

    it "defaults id to nil" do
      widget = Ratatat::Widget.new
      expect(widget.id).to be_nil
    end

    it "has classes set" do
      widget = Ratatat::Widget.new(classes: %w[active primary])
      expect(widget.classes).to include("active", "primary")
    end

    it "defaults classes to empty" do
      widget = Ratatat::Widget.new
      expect(widget.classes).to be_empty
    end
  end

  describe "tree structure" do
    it "starts with no parent" do
      widget = Ratatat::Widget.new
      expect(widget.parent).to be_nil
    end

    it "starts with no children" do
      widget = Ratatat::Widget.new
      expect(widget.children).to be_empty
    end

    describe "#mount" do
      it "adds children" do
        parent = Ratatat::Widget.new
        child1 = Ratatat::Widget.new(id: "c1")
        child2 = Ratatat::Widget.new(id: "c2")

        parent.mount(child1, child2)

        expect(parent.children).to eq([child1, child2])
      end

      it "sets parent on children" do
        parent = Ratatat::Widget.new
        child = Ratatat::Widget.new

        parent.mount(child)

        expect(child.parent).to eq(parent)
      end

      it "returns self for chaining" do
        parent = Ratatat::Widget.new
        result = parent.mount(Ratatat::Widget.new)
        expect(result).to eq(parent)
      end
    end

    describe "#remove" do
      it "removes self from parent" do
        parent = Ratatat::Widget.new
        child = Ratatat::Widget.new
        parent.mount(child)

        child.remove

        expect(parent.children).to be_empty
        expect(child.parent).to be_nil
      end
    end

    describe "#ancestors" do
      it "returns parent chain" do
        grandparent = Ratatat::Widget.new(id: "gp")
        parent = Ratatat::Widget.new(id: "p")
        child = Ratatat::Widget.new(id: "c")

        grandparent.mount(parent)
        parent.mount(child)

        expect(child.ancestors).to eq([parent, grandparent])
      end
    end
  end

  describe "focus" do
    it "defaults can_focus to false" do
      widget = Ratatat::Widget.new
      expect(widget.can_focus?).to eq(false)
    end

    it "respects CAN_FOCUS class constant" do
      focusable_class = Class.new(Ratatat::Widget)
      focusable_class.const_set(:CAN_FOCUS, true)
      widget = focusable_class.new
      expect(widget.can_focus?).to eq(true)
    end

    it "tracks focus state" do
      widget = Ratatat::Widget.new
      expect(widget.has_focus?).to eq(false)
    end
  end

  describe "message dispatch" do
    it "calls on_<message_name> handler" do
      handler_class = Class.new(Ratatat::Widget) do
        attr_reader :received_key

        def on_key(message)
          @received_key = message.key
        end
      end

      widget = handler_class.new
      message = Ratatat::Key.new(sender: widget, key: :up)

      widget.dispatch(message)

      expect(widget.received_key).to eq(:up)
    end

    it "does nothing if no handler" do
      widget = Ratatat::Widget.new
      message = Ratatat::Key.new(sender: widget, key: :up)

      expect { widget.dispatch(message) }.not_to raise_error
    end

    it "bubbles to parent" do
      parent_class = Class.new(Ratatat::Widget) do
        attr_reader :received

        def on_key(message)
          @received = true
        end
      end

      parent = parent_class.new
      child = Ratatat::Widget.new
      parent.mount(child)

      message = Ratatat::Key.new(sender: child, key: :up)
      child.dispatch(message)

      expect(parent.received).to eq(true)
    end

    it "stops bubbling when message.stop called" do
      parent_class = Class.new(Ratatat::Widget) do
        attr_reader :received

        def on_key(message)
          @received = true
        end
      end

      child_class = Class.new(Ratatat::Widget) do
        def on_key(message)
          message.stop
        end
      end

      parent = parent_class.new
      child = child_class.new
      parent.mount(child)

      message = Ratatat::Key.new(sender: child, key: :up)
      child.dispatch(message)

      expect(parent.received).to be_nil
    end

    it "does not bubble when bubble: false" do
      parent_class = Class.new(Ratatat::Widget) do
        attr_reader :received

        def on_key(message)
          @received = true
        end
      end

      parent = parent_class.new
      child = Ratatat::Widget.new
      parent.mount(child)

      message = Ratatat::Key.new(sender: child, key: :up, bubble: false)
      child.dispatch(message)

      expect(parent.received).to be_nil
    end
  end

  describe "#query" do
    before do
      @root = Ratatat::Widget.new(id: "root")
      @child1 = Ratatat::Widget.new(id: "c1", classes: ["active"])
      @child2 = Ratatat::Widget.new(id: "c2", classes: ["inactive"])
      @grandchild = Ratatat::Widget.new(id: "gc", classes: ["active"])

      @root.mount(@child1, @child2)
      @child1.mount(@grandchild)
    end

    it "finds by id" do
      result = @root.query("#c1")
      expect(result).to eq([@child1])
    end

    it "finds by class" do
      result = @root.query(".active")
      expect(result).to contain_exactly(@child1, @grandchild)
    end

    it "finds by type" do
      custom_class = Class.new(Ratatat::Widget)
      typed = custom_class.new
      @root.mount(typed)

      result = @root.query(custom_class)
      expect(result).to eq([typed])
    end

    it "returns empty for no match" do
      result = @root.query("#nonexistent")
      expect(result).to be_empty
    end
  end

  describe "#query_one" do
    it "returns first match" do
      root = Ratatat::Widget.new
      child = Ratatat::Widget.new(id: "target")
      root.mount(child)

      expect(root.query_one("#target")).to eq(child)
    end

    it "returns nil for no match" do
      root = Ratatat::Widget.new
      expect(root.query_one("#missing")).to be_nil
    end
  end

  describe "#query_one!" do
    it "raises for no match" do
      root = Ratatat::Widget.new
      expect { root.query_one!("#missing") }.to raise_error(Ratatat::QueryError)
    end
  end
end
