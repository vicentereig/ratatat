# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::Styles do
  describe "basic properties" do
    it "has foreground color" do
      styles = Ratatat::Styles.new
      styles.foreground = :red
      expect(styles.foreground).to eq(:red)
    end

    it "has background color" do
      styles = Ratatat::Styles.new
      styles.background = :blue
      expect(styles.background).to eq(:blue)
    end

    it "has width and height" do
      styles = Ratatat::Styles.new
      styles.width = 10
      styles.height = 5
      expect(styles.width).to eq(10)
      expect(styles.height).to eq(5)
    end

    it "has padding" do
      styles = Ratatat::Styles.new
      styles.padding = [1, 2, 1, 2]
      expect(styles.padding).to eq([1, 2, 1, 2])
    end

    it "has bold and italic" do
      styles = Ratatat::Styles.new
      styles.bold = true
      styles.italic = true
      expect(styles.bold).to be true
      expect(styles.italic).to be true
    end
  end

  describe "initialization from hash" do
    it "accepts properties as hash" do
      styles = Ratatat::Styles.new(foreground: :green, background: :black, bold: true)
      expect(styles.foreground).to eq(:green)
      expect(styles.background).to eq(:black)
      expect(styles.bold).to be true
    end
  end

  describe "merge" do
    it "combines two styles" do
      base = Ratatat::Styles.new(foreground: :white, background: :black)
      override = Ratatat::Styles.new(foreground: :red)
      merged = base.merge(override)

      expect(merged.foreground).to eq(:red)
      expect(merged.background).to eq(:black)
    end

    it "does not modify originals" do
      base = Ratatat::Styles.new(foreground: :white)
      override = Ratatat::Styles.new(foreground: :red)
      base.merge(override)

      expect(base.foreground).to eq(:white)
    end
  end
end

RSpec.describe "Widget styling" do
  describe "inline styles" do
    it "accepts styles in constructor" do
      static = Ratatat::Static.new("Hello", styles: { foreground: :red })
      expect(static.styles.foreground).to eq(:red)
    end

    it "has mutable styles" do
      static = Ratatat::Static.new("Hello")
      static.styles.background = :blue
      expect(static.styles.background).to eq(:blue)
    end
  end

  describe "class management" do
    it "adds classes with add_class" do
      widget = Ratatat::Widget.new
      widget.add_class("active")
      expect(widget.classes).to include("active")
    end

    it "removes classes with remove_class" do
      widget = Ratatat::Widget.new(classes: ["active", "primary"])
      widget.remove_class("active")
      expect(widget.classes).not_to include("active")
      expect(widget.classes).to include("primary")
    end

    it "toggles classes with toggle_class" do
      widget = Ratatat::Widget.new
      widget.toggle_class("active")
      expect(widget.classes).to include("active")

      widget.toggle_class("active")
      expect(widget.classes).not_to include("active")
    end

    it "conditionally sets class with set_class" do
      widget = Ratatat::Widget.new
      widget.set_class(true, "active")
      expect(widget.classes).to include("active")

      widget.set_class(false, "active")
      expect(widget.classes).not_to include("active")
    end

    it "checks class with has_class?" do
      widget = Ratatat::Widget.new(classes: ["active"])
      expect(widget.has_class?("active")).to be true
      expect(widget.has_class?("inactive")).to be false
    end
  end
end

RSpec.describe Ratatat::StyleSheet do
  describe "rule parsing" do
    it "parses type selector" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Button", foreground: :white, background: :blue)

      button = Ratatat::Button.new("Click")
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:white)
      expect(styles.background).to eq(:blue)
    end

    it "parses id selector" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("#submit", background: :green)

      button = Ratatat::Button.new("Submit", id: "submit")
      styles = sheet.compute(button)

      expect(styles.background).to eq(:green)
    end

    it "parses class selector" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule(".primary", foreground: :cyan)

      button = Ratatat::Button.new("OK", classes: ["primary"])
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:cyan)
    end
  end

  describe "specificity" do
    it "id beats class beats type" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Button", foreground: :white)
      sheet.add_rule(".primary", foreground: :blue)
      sheet.add_rule("#submit", foreground: :green)

      button = Ratatat::Button.new("Submit", id: "submit", classes: ["primary"])
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:green)
    end
  end

  describe "multiple rules" do
    it "combines matching rules" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Button", foreground: :white)
      sheet.add_rule(".primary", background: :blue)

      button = Ratatat::Button.new("OK", classes: ["primary"])
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:white)
      expect(styles.background).to eq(:blue)
    end
  end

  describe "descendant combinator" do
    it "matches widget inside ancestor" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Container Button", foreground: :red)

      container = Ratatat::Container.new
      button = Ratatat::Button.new("Click")
      container.mount(button)

      styles = sheet.compute(button)
      expect(styles.foreground).to eq(:red)
    end

    it "does not match widget without ancestor" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Modal Button", foreground: :red)

      container = Ratatat::Container.new
      button = Ratatat::Button.new("Click")
      container.mount(button)

      styles = sheet.compute(button)
      expect(styles.foreground).to be_nil
    end

    it "matches deeply nested widget" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Container Button", foreground: :blue)

      outer = Ratatat::Container.new
      inner = Ratatat::Container.new
      button = Ratatat::Button.new("Deep")
      outer.mount(inner)
      inner.mount(button)

      styles = sheet.compute(button)
      expect(styles.foreground).to eq(:blue)
    end
  end

  describe "child combinator" do
    it "matches direct child" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Container > Button", foreground: :green)

      container = Ratatat::Container.new
      button = Ratatat::Button.new("Direct")
      container.mount(button)

      styles = sheet.compute(button)
      expect(styles.foreground).to eq(:green)
    end

    it "does not match non-direct descendant" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Modal > Button", foreground: :green)

      modal = Ratatat::Modal.new
      container = Ratatat::Container.new
      button = Ratatat::Button.new("Nested")
      modal.mount(container)
      container.mount(button)

      # Button is child of Container, not Modal directly
      styles = sheet.compute(button)
      expect(styles.foreground).to be_nil
    end
  end

  describe ":not() selector" do
    it "excludes matching widgets" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Button:not(.danger)", foreground: :white)

      safe = Ratatat::Button.new("Safe", classes: ["primary"])
      danger = Ratatat::Button.new("Danger", classes: ["danger"])

      expect(sheet.compute(safe).foreground).to eq(:white)
      expect(sheet.compute(danger).foreground).to be_nil
    end

    it "works with id selectors" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Button:not(#skip)", background: :blue)

      normal = Ratatat::Button.new("Normal")
      skip = Ratatat::Button.new("Skip", id: "skip")

      expect(sheet.compute(normal).background).to eq(:blue)
      expect(sheet.compute(skip).background).to be_nil
    end
  end

  describe "compound selectors" do
    it "matches type and class" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Button.primary", foreground: :cyan)

      primary_button = Ratatat::Button.new("Primary", classes: ["primary"])
      plain_button = Ratatat::Button.new("Plain")
      primary_static = Ratatat::Static.new("Text", classes: ["primary"])

      expect(sheet.compute(primary_button).foreground).to eq(:cyan)
      expect(sheet.compute(plain_button).foreground).to be_nil
      expect(sheet.compute(primary_static).foreground).to be_nil
    end

    it "matches type and id" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule("Button#submit", background: :green)

      submit = Ratatat::Button.new("Submit", id: "submit")
      other = Ratatat::Button.new("Other", id: "cancel")

      expect(sheet.compute(submit).background).to eq(:green)
      expect(sheet.compute(other).background).to be_nil
    end

    it "matches multiple classes" do
      sheet = Ratatat::StyleSheet.new
      sheet.add_rule(".primary.large", bold: true)

      both = Ratatat::Button.new("Both", classes: ["primary", "large"])
      one = Ratatat::Button.new("One", classes: ["primary"])

      expect(sheet.compute(both).bold).to be true
      expect(sheet.compute(one).bold).to be_nil
    end
  end
end
