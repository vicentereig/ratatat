# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::Color do
  describe Ratatat::Color::Named do
    it "is a T::Enum with standard colors" do
      expect(Ratatat::Color::Named::Reset).to be_a(Ratatat::Color::Named)
      expect(Ratatat::Color::Named::Red).to be_a(Ratatat::Color::Named)
      expect(Ratatat::Color::Named::BrightBlue).to be_a(Ratatat::Color::Named)
    end

    it "serializes to symbol" do
      expect(Ratatat::Color::Named::Red.serialize).to eq(:red)
      expect(Ratatat::Color::Named::BrightGreen.serialize).to eq(:bright_green)
    end

    it "provides ANSI foreground codes" do
      expect(Ratatat::Color::Named::Red.fg_code).to eq(31)
      expect(Ratatat::Color::Named::BrightBlue.fg_code).to eq(94)
      expect(Ratatat::Color::Named::Reset.fg_code).to eq(39)
    end

    it "provides ANSI background codes" do
      expect(Ratatat::Color::Named::Red.bg_code).to eq(41)
      expect(Ratatat::Color::Named::Reset.bg_code).to eq(49)
    end
  end

  describe Ratatat::Color::Indexed do
    it "is a T::Struct with index" do
      color = Ratatat::Color::Indexed.new(index: 196)
      expect(color.index).to eq(196)
    end

    it "validates range 0-255" do
      expect { Ratatat::Color::Indexed.new(index: -1) }.to raise_error(ArgumentError)
      expect { Ratatat::Color::Indexed.new(index: 256) }.to raise_error(ArgumentError)
      expect { Ratatat::Color::Indexed.new(index: 0) }.not_to raise_error
      expect { Ratatat::Color::Indexed.new(index: 255) }.not_to raise_error
    end

    it "compares by index" do
      expect(Ratatat::Color::Indexed.new(index: 100)).to eq(Ratatat::Color::Indexed.new(index: 100))
      expect(Ratatat::Color::Indexed.new(index: 100)).not_to eq(Ratatat::Color::Indexed.new(index: 101))
    end

    it "generates ANSI codes" do
      color = Ratatat::Color::Indexed.new(index: 196)
      expect(color.fg_code).to eq("38;5;196")
      expect(color.bg_code).to eq("48;5;196")
    end
  end

  describe Ratatat::Color::Rgb do
    it "is a T::Struct with r, g, b" do
      color = Ratatat::Color::Rgb.new(r: 255, g: 128, b: 0)
      expect(color.r).to eq(255)
      expect(color.g).to eq(128)
      expect(color.b).to eq(0)
    end

    it "validates range 0-255 for each component" do
      expect { Ratatat::Color::Rgb.new(r: -1, g: 0, b: 0) }.to raise_error(ArgumentError)
      expect { Ratatat::Color::Rgb.new(r: 256, g: 0, b: 0) }.to raise_error(ArgumentError)
      expect { Ratatat::Color::Rgb.new(r: 0, g: 0, b: 0) }.not_to raise_error
      expect { Ratatat::Color::Rgb.new(r: 255, g: 255, b: 255) }.not_to raise_error
    end

    it "compares by RGB values" do
      expect(Ratatat::Color::Rgb.new(r: 255, g: 0, b: 0)).to eq(Ratatat::Color::Rgb.new(r: 255, g: 0, b: 0))
      expect(Ratatat::Color::Rgb.new(r: 255, g: 0, b: 0)).not_to eq(Ratatat::Color::Rgb.new(r: 0, g: 255, b: 0))
    end

    it "generates ANSI codes" do
      color = Ratatat::Color::Rgb.new(r: 255, g: 128, b: 0)
      expect(color.fg_code).to eq("38;2;255;128;0")
      expect(color.bg_code).to eq("48;2;255;128;0")
    end
  end

  describe ".hex" do
    it "parses 6-digit hex" do
      color = Ratatat::Color.hex("#ff8000")
      expect(color).to be_a(Ratatat::Color::Rgb)
      expect(color.r).to eq(255)
      expect(color.g).to eq(128)
      expect(color.b).to eq(0)
    end

    it "parses 3-digit hex" do
      color = Ratatat::Color.hex("#f80")
      expect(color.r).to eq(255)
      expect(color.g).to eq(136)
      expect(color.b).to eq(0)
    end

    it "works without # prefix" do
      color = Ratatat::Color.hex("ff0000")
      expect(color.r).to eq(255)
    end

    it "raises on invalid hex" do
      expect { Ratatat::Color.hex("invalid") }.to raise_error(ArgumentError)
      expect { Ratatat::Color.hex("#12") }.to raise_error(ArgumentError)
    end
  end

  describe ".fg_ansi / .bg_ansi" do
    it "works with Named colors" do
      expect(Ratatat::Color.fg_ansi(Ratatat::Color::Named::Red)).to eq("31")
    end

    it "works with Indexed colors" do
      expect(Ratatat::Color.fg_ansi(Ratatat::Color::Indexed.new(index: 196))).to eq("38;5;196")
    end

    it "works with Rgb colors" do
      expect(Ratatat::Color.fg_ansi(Ratatat::Color::Rgb.new(r: 255, g: 0, b: 0))).to eq("38;2;255;0;0")
    end
  end
end
