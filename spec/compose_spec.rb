# typed: false
require_relative "spec_helper"

RSpec.describe "Composition" do
  describe "#compose" do
    it "mounts returned widgets as children" do
      child_class = Class.new(Ratatat::Widget)

      parent_class = Class.new(Ratatat::Widget) do
        define_method(:compose) do
          [child_class.new(id: "c1"), child_class.new(id: "c2")]
        end
      end

      app = Ratatat::App.new
      parent = parent_class.new
      app.mount(parent)

      expect(parent.children.length).to eq(2)
      expect(parent.children[0].id).to eq("c1")
      expect(parent.children[1].id).to eq("c2")
    end

    it "triggers on_mount for composed children" do
      mounted = []
      child_class = Class.new(Ratatat::Widget) do
        define_method(:on_mount) do
          mounted << id
        end
      end

      parent_class = Class.new(Ratatat::Widget) do
        define_method(:compose) do
          [child_class.new(id: "c1"), child_class.new(id: "c2")]
        end
      end

      app = Ratatat::App.new
      parent = parent_class.new(id: "parent")
      app.mount(parent)

      expect(mounted).to contain_exactly("c1", "c2")
    end

    it "supports nested composition" do
      leaf_class = Class.new(Ratatat::Widget)

      inner_class = Class.new(Ratatat::Widget) do
        define_method(:compose) do
          [leaf_class.new(id: "leaf")]
        end
      end

      outer_class = Class.new(Ratatat::Widget) do
        define_method(:compose) do
          [inner_class.new(id: "inner")]
        end
      end

      app = Ratatat::App.new
      outer = outer_class.new(id: "outer")
      app.mount(outer)

      expect(outer.children.length).to eq(1)
      inner = outer.children.first
      expect(inner.id).to eq("inner")
      expect(inner.children.length).to eq(1)
      expect(inner.children.first.id).to eq("leaf")
    end
  end

  describe "App#compose" do
    it "composes app children on run setup" do
      child_class = Class.new(Ratatat::Widget)

      app_class = Class.new(Ratatat::App) do
        define_method(:compose) do
          [child_class.new(id: "main")]
        end
      end

      app = app_class.new
      # Manually trigger compose since we're not calling run()
      app.send(:do_compose)

      expect(app.children.length).to eq(1)
      expect(app.children.first.id).to eq("main")
    end
  end

  describe "recompose" do
    it "rebuilds children when recompose called" do
      counter = { value: 0 }
      child_class = Class.new(Ratatat::Widget)

      parent_class = Class.new(Ratatat::Widget) do
        reactive :item_count, default: 1

        define_method(:compose) do
          counter[:value] += 1
          item_count.times.map { |i| child_class.new(id: "item_#{i}") }
        end
      end

      app = Ratatat::App.new
      parent = parent_class.new
      app.mount(parent)

      expect(parent.children.length).to eq(1)
      expect(counter[:value]).to eq(1)

      parent.item_count = 3
      parent.recompose

      expect(parent.children.length).to eq(3)
      expect(counter[:value]).to eq(2)
    end
  end
end
