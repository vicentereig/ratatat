# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::DOMQuery do
  let(:app) { Ratatat::App.new }
  let(:container) { Ratatat::Container.new(id: "main") }
  let(:button1) { Ratatat::Button.new("One", id: "btn1", classes: ["primary"]) }
  let(:button2) { Ratatat::Button.new("Two", id: "btn2", classes: ["secondary"]) }
  let(:button3) { Ratatat::Button.new("Three", id: "btn3", classes: ["primary", "large"]) }
  let(:static) { Ratatat::Static.new("Text") }

  before do
    app.mount(container)
    container.mount(button1, button2, button3, static)
  end

  describe "query" do
    it "finds widgets by type" do
      result = app.query("Button")
      expect(result.to_a.length).to eq(3)
    end

    it "finds widgets by id" do
      result = app.query("#btn1")
      expect(result.first).to eq(button1)
    end

    it "finds widgets by class" do
      result = app.query(".primary")
      expect(result.to_a).to contain_exactly(button1, button3)
    end

    it "returns DOMQuery object" do
      result = app.query("Button")
      expect(result).to be_a(Ratatat::DOMQuery)
    end
  end

  describe "filter" do
    it "filters by class" do
      result = app.query("Button").filter(".large")
      expect(result.to_a).to eq([button3])
    end

    it "filters by id" do
      result = app.query("Button").filter("#btn2")
      expect(result.to_a).to eq([button2])
    end

    it "is chainable" do
      result = app.query("Button").filter(".primary").filter(".large")
      expect(result.to_a).to eq([button3])
    end
  end

  describe "exclude" do
    it "excludes by class" do
      result = app.query("Button").exclude(".primary")
      expect(result.to_a).to eq([button2])
    end

    it "excludes by id" do
      result = app.query("Button").exclude("#btn1")
      expect(result.to_a).to contain_exactly(button2, button3)
    end

    it "is chainable" do
      result = app.query("Button").exclude(".secondary").exclude(".large")
      expect(result.to_a).to eq([button1])
    end
  end

  describe "first and last" do
    it "returns first matching widget" do
      result = app.query("Button").first
      expect(result).to be_a(Ratatat::Button)
    end

    it "returns last matching widget" do
      result = app.query("Button").last
      expect(result).to be_a(Ratatat::Button)
    end

    it "returns nil when no matches" do
      result = app.query("Modal").first
      expect(result).to be_nil
    end
  end

  describe "each" do
    it "iterates over matches" do
      ids = []
      app.query("Button").each { |b| ids << b.id }
      expect(ids).to contain_exactly("btn1", "btn2", "btn3")
    end
  end

  describe "count" do
    it "returns number of matches" do
      expect(app.query("Button").count).to eq(3)
      expect(app.query(".primary").count).to eq(2)
      expect(app.query("#btn1").count).to eq(1)
    end
  end

  describe "empty?" do
    it "returns true when no matches" do
      expect(app.query("Modal").empty?).to be true
    end

    it "returns false when matches exist" do
      expect(app.query("Button").empty?).to be false
    end
  end

  describe "bulk add_class" do
    it "adds class to all matched widgets" do
      app.query("Button").add_class("highlighted")

      expect(button1.classes).to include("highlighted")
      expect(button2.classes).to include("highlighted")
      expect(button3.classes).to include("highlighted")
    end

    it "returns self for chaining" do
      result = app.query("Button").add_class("a").add_class("b")
      expect(result).to be_a(Ratatat::DOMQuery)
      expect(button1.classes).to include("a", "b")
    end
  end

  describe "bulk remove_class" do
    it "removes class from all matched widgets" do
      app.query(".primary").remove_class("primary")

      expect(button1.classes).not_to include("primary")
      expect(button3.classes).not_to include("primary")
    end
  end

  describe "bulk toggle_class" do
    it "toggles class on all matched widgets" do
      app.query("Button").toggle_class("toggled")

      expect(button1.classes).to include("toggled")
      expect(button2.classes).to include("toggled")

      app.query("Button").toggle_class("toggled")

      expect(button1.classes).not_to include("toggled")
      expect(button2.classes).not_to include("toggled")
    end
  end

  describe "bulk remove" do
    it "removes all matched widgets from parents" do
      expect(container.children.length).to eq(4)

      app.query(".primary").remove

      expect(container.children.length).to eq(2)
      expect(container.children).not_to include(button1)
      expect(container.children).not_to include(button3)
    end
  end

  describe "focus" do
    it "focuses the first matched widget" do
      app.query("Button").focus

      expect(app.focused).to eq(button1)
    end

    it "returns the focused widget" do
      result = app.query("#btn2").focus
      expect(result).to eq(button2)
    end

    it "returns nil when no matches" do
      result = app.query("Modal").focus
      expect(result).to be_nil
    end
  end

  describe "set_styles" do
    it "sets styles on all matched widgets" do
      app.query("Button").set_styles(foreground: :red, bold: true)

      expect(button1.styles.foreground).to eq(:red)
      expect(button1.styles.bold).to be true
      expect(button2.styles.foreground).to eq(:red)
      expect(button3.styles.foreground).to eq(:red)
    end

    it "returns self for chaining" do
      result = app.query("Button").set_styles(foreground: :blue)
      expect(result).to be_a(Ratatat::DOMQuery)
    end
  end
end
