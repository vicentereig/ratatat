# typed: false
require_relative "spec_helper"

RSpec.describe "Pseudo-classes" do
  describe ":focus" do
    it "applies styles when widget has focus" do
      css = <<~CSS
        Button {
          background: blue;
        }
        Button:focus {
          background: cyan;
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      app = Ratatat::App.new
      button = Ratatat::Button.new("Test")
      app.mount(button)

      # Without focus
      styles = sheet.compute(button)
      expect(styles.background).to eq(:blue)

      # With focus
      button.focus
      styles = sheet.compute(button)
      expect(styles.background).to eq(:cyan)
    end
  end

  describe ":disabled" do
    it "applies styles when widget is disabled" do
      css = <<~CSS
        Button {
          foreground: white;
        }
        Button:disabled {
          foreground: gray;
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      button = Ratatat::Button.new("Test")

      # Without disabled
      styles = sheet.compute(button)
      expect(styles.foreground).to eq(:white)

      # With disabled
      button.disabled = true
      styles = sheet.compute(button)
      expect(styles.foreground).to eq(:gray)
    end
  end

  describe ":hover" do
    it "applies styles when widget is hovered" do
      css = <<~CSS
        Button {
          background: blue;
        }
        Button:hover {
          background: bright_blue;
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      button = Ratatat::Button.new("Test")

      # Without hover
      styles = sheet.compute(button)
      expect(styles.background).to eq(:blue)

      # With hover
      button.instance_variable_set(:@hover, true)
      styles = sheet.compute(button)
      expect(styles.background).to eq(:bright_blue)
    end
  end

  describe "compound selectors" do
    it "handles type + pseudo-class" do
      css = "Button:focus { bold: true; }"
      sheet = Ratatat::CSSParser.parse(css)

      app = Ratatat::App.new
      button = Ratatat::Button.new("Test")
      app.mount(button)
      button.focus

      styles = sheet.compute(button)
      expect(styles.bold).to be true
    end

    it "handles class + pseudo-class" do
      css = ".primary:focus { italic: true; }"
      sheet = Ratatat::CSSParser.parse(css)

      app = Ratatat::App.new
      button = Ratatat::Button.new("Test", classes: ["primary"])
      app.mount(button)
      button.focus

      styles = sheet.compute(button)
      expect(styles.italic).to be true
    end

    it "handles id + pseudo-class" do
      css = "#submit:disabled { foreground: red; }"
      sheet = Ratatat::CSSParser.parse(css)

      button = Ratatat::Button.new("Submit", id: "submit")
      button.disabled = true

      styles = sheet.compute(button)
      expect(styles.foreground).to eq(:red)
    end
  end

  describe "specificity with pseudo-classes" do
    it "pseudo-class adds to specificity" do
      css = <<~CSS
        Button { foreground: white; }
        Button:focus { foreground: yellow; }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      app = Ratatat::App.new
      button = Ratatat::Button.new("Test")
      app.mount(button)
      button.focus

      styles = sheet.compute(button)
      expect(styles.foreground).to eq(:yellow)
    end
  end
end
