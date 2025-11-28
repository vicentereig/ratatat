# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::CSSParser do
  describe "basic parsing" do
    it "parses type selector with properties" do
      css = <<~CSS
        Button {
          foreground: white;
          background: blue;
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      button = Ratatat::Button.new("Test")
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:white)
      expect(styles.background).to eq(:blue)
    end

    it "parses id selector" do
      css = <<~CSS
        #submit {
          background: green;
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      button = Ratatat::Button.new("Submit", id: "submit")
      styles = sheet.compute(button)

      expect(styles.background).to eq(:green)
    end

    it "parses class selector" do
      css = <<~CSS
        .primary {
          foreground: cyan;
          bold: true;
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      button = Ratatat::Button.new("OK", classes: ["primary"])
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:cyan)
      expect(styles.bold).to be true
    end

    it "parses multiple rules" do
      css = <<~CSS
        Button {
          foreground: white;
        }

        .primary {
          background: blue;
        }

        #submit {
          bold: true;
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      button = Ratatat::Button.new("Submit", id: "submit", classes: ["primary"])
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:white)
      expect(styles.background).to eq(:blue)
      expect(styles.bold).to be true
    end
  end

  describe "color values" do
    it "parses named colors" do
      css = "Static { foreground: red; background: bright_blue; }"
      sheet = Ratatat::CSSParser.parse(css)
      static = Ratatat::Static.new("Test")
      styles = sheet.compute(static)

      expect(styles.foreground).to eq(:red)
      expect(styles.background).to eq(:bright_blue)
    end

    it "parses hex colors" do
      css = "Static { foreground: #ff0000; background: #00ff00; }"
      sheet = Ratatat::CSSParser.parse(css)
      static = Ratatat::Static.new("Test")
      styles = sheet.compute(static)

      expect(styles.foreground).to be_a(Ratatat::Color::Rgb)
      expect(styles.foreground.r).to eq(255)
      expect(styles.foreground.g).to eq(0)
    end

    it "parses rgb colors" do
      css = "Static { foreground: rgb(255, 128, 0); }"
      sheet = Ratatat::CSSParser.parse(css)
      static = Ratatat::Static.new("Test")
      styles = sheet.compute(static)

      expect(styles.foreground).to be_a(Ratatat::Color::Rgb)
      expect(styles.foreground.r).to eq(255)
      expect(styles.foreground.g).to eq(128)
      expect(styles.foreground.b).to eq(0)
    end
  end

  describe "numeric values" do
    it "parses integer values" do
      css = "Container { width: 100; height: 50; }"
      sheet = Ratatat::CSSParser.parse(css)
      container = Ratatat::Container.new
      styles = sheet.compute(container)

      expect(styles.width).to eq(100)
      expect(styles.height).to eq(50)
    end

    it "parses padding shorthand" do
      css = "Container { padding: 1 2 1 2; }"
      sheet = Ratatat::CSSParser.parse(css)
      container = Ratatat::Container.new
      styles = sheet.compute(container)

      expect(styles.padding).to eq([1, 2, 1, 2])
    end
  end

  describe "boolean values" do
    it "parses true/false" do
      css = "Static { bold: true; italic: false; }"
      sheet = Ratatat::CSSParser.parse(css)
      static = Ratatat::Static.new("Test")
      styles = sheet.compute(static)

      expect(styles.bold).to be true
      expect(styles.italic).to be false
    end
  end

  describe "comments" do
    it "ignores single-line comments" do
      css = <<~CSS
        /* This is a comment */
        Button {
          foreground: white; /* inline comment */
        }
      CSS

      sheet = Ratatat::CSSParser.parse(css)
      button = Ratatat::Button.new("Test")
      styles = sheet.compute(button)

      expect(styles.foreground).to eq(:white)
    end
  end

  describe "App CSS constant" do
    it "loads CSS from App::CSS constant" do
      app_class = Class.new(Ratatat::App) do
        const_set(:CSS, <<~CSS)
          Button {
            foreground: yellow;
          }
        CSS
      end

      app = app_class.new
      expect(app.stylesheet).to be_a(Ratatat::StyleSheet)

      button = Ratatat::Button.new("Test")
      app.mount(button)
      styles = app.stylesheet.compute(button)

      expect(styles.foreground).to eq(:yellow)
    end
  end
end
