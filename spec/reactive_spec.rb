# typed: false
require_relative "spec_helper"

RSpec.describe "Reactive Properties" do
  describe "basic reactive" do
    it "defines getter and setter" do
      widget_class = Class.new(Ratatat::Widget) do
        reactive :count, default: 0
      end

      widget = widget_class.new
      expect(widget.count).to eq(0)

      widget.count = 5
      expect(widget.count).to eq(5)
    end

    it "uses default value" do
      widget_class = Class.new(Ratatat::Widget) do
        reactive :name, default: "untitled"
      end

      widget = widget_class.new
      expect(widget.name).to eq("untitled")
    end
  end

  describe "watch_<name>" do
    it "calls watcher when value changes" do
      changes = []
      widget_class = Class.new(Ratatat::Widget) do
        reactive :count, default: 0

        define_method(:watch_count) do |old_val, new_val|
          changes << [old_val, new_val]
        end
      end

      widget = widget_class.new
      widget.count = 1
      widget.count = 2

      expect(changes).to eq([[0, 1], [1, 2]])
    end

    it "does not call watcher if value unchanged" do
      calls = 0
      widget_class = Class.new(Ratatat::Widget) do
        reactive :count, default: 0

        define_method(:watch_count) do |_old, _new|
          calls += 1
        end
      end

      widget = widget_class.new
      widget.count = 0
      widget.count = 0

      expect(calls).to eq(0)
    end
  end

  describe "validate_<name>" do
    it "transforms value before storage" do
      widget_class = Class.new(Ratatat::Widget) do
        reactive :count, default: 0

        def validate_count(value)
          value.clamp(0, 100)
        end
      end

      widget = widget_class.new
      widget.count = 150
      expect(widget.count).to eq(100)

      widget.count = -10
      expect(widget.count).to eq(0)
    end
  end

  describe "repaint option" do
    it "calls refresh when repaint: true" do
      refreshed = false
      widget_class = Class.new(Ratatat::Widget) do
        reactive :count, default: 0, repaint: true

        define_method(:refresh) do
          refreshed = true
        end
      end

      widget = widget_class.new
      widget.count = 1

      expect(refreshed).to eq(true)
    end

    it "does not call refresh when repaint: false" do
      refreshed = false
      widget_class = Class.new(Ratatat::Widget) do
        reactive :count, default: 0, repaint: false

        define_method(:refresh) do
          refreshed = true
        end
      end

      widget = widget_class.new
      widget.count = 1

      expect(refreshed).to eq(false)
    end
  end

  describe "multiple reactives" do
    it "tracks each independently" do
      widget_class = Class.new(Ratatat::Widget) do
        reactive :x, default: 0
        reactive :y, default: 0
      end

      widget = widget_class.new
      widget.x = 10
      widget.y = 20

      expect(widget.x).to eq(10)
      expect(widget.y).to eq(20)
    end
  end

  describe "initialization" do
    it "accepts initial values in constructor" do
      widget_class = Class.new(Ratatat::Widget) do
        reactive :count, default: 0
        reactive :name, default: "default"
      end

      widget = widget_class.new(count: 5, name: "custom")

      expect(widget.count).to eq(5)
      expect(widget.name).to eq("custom")
    end
  end
end
