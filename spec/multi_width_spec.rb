# typed: false
require_relative "spec_helper"

RSpec.describe "Multi-width character support" do
  describe Ratatat::Cell do
    it "returns width 1 for ASCII characters" do
      cell = Ratatat::Cell.new(symbol: "A")
      expect(cell.width).to eq(1)
    end

    it "returns width 2 for CJK characters" do
      cell = Ratatat::Cell.new(symbol: "日")
      expect(cell.width).to eq(2)
    end

    it "returns width 2 for emoji" do
      cell = Ratatat::Cell.new(symbol: "🚀")
      expect(cell.width).to eq(2)
    end

    it "returns width 1 for empty string" do
      cell = Ratatat::Cell.new(symbol: "")
      expect(cell.width).to eq(1)
    end

    it "handles Hangul characters" do
      cell = Ratatat::Cell.new(symbol: "한")
      expect(cell.width).to eq(2)
    end

    it "handles fullwidth characters" do
      cell = Ratatat::Cell.new(symbol: "Ａ") # Fullwidth A
      expect(cell.width).to eq(2)
    end
  end

  describe Ratatat::Buffer do
    it "handles CJK characters in put_string" do
      buffer = Ratatat::Buffer.new(10, 1)
      buffer.put_string(0, 0, "日本")

      # Each CJK character takes 2 cells
      # Cell 0: "日", Cell 1: "" (continuation)
      # Cell 2: "本", Cell 3: "" (continuation)
      expect(buffer[0, 0].symbol).to eq("日")
      expect(buffer[1, 0].symbol).to eq("")
      expect(buffer[2, 0].symbol).to eq("本")
      expect(buffer[3, 0].symbol).to eq("")
    end

    it "handles emoji in put_string" do
      buffer = Ratatat::Buffer.new(10, 1)
      buffer.put_string(0, 0, "🚀A")

      # Emoji takes 2 cells, A takes 1
      expect(buffer[0, 0].symbol).to eq("🚀")
      expect(buffer[1, 0].symbol).to eq("")
      expect(buffer[2, 0].symbol).to eq("A")
    end

    it "handles mixed width characters" do
      buffer = Ratatat::Buffer.new(10, 1)
      buffer.put_string(0, 0, "A日B")

      expect(buffer[0, 0].symbol).to eq("A")
      expect(buffer[1, 0].symbol).to eq("日")
      expect(buffer[2, 0].symbol).to eq("")
      expect(buffer[3, 0].symbol).to eq("B")
    end

    it "clips wide characters at buffer boundary" do
      buffer = Ratatat::Buffer.new(3, 1)
      buffer.put_string(0, 0, "日本語")

      # Only the first character should fit
      expect(buffer[0, 0].symbol).to eq("日")
      expect(buffer[1, 0].symbol).to eq("")
      expect(buffer[2, 0].symbol).to eq("本")
    end
  end

  describe "Widget rendering with multi-width" do
    it "renders static with CJK text" do
      static = Ratatat::Static.new("日本語")
      buffer = Ratatat::Buffer.new(10, 1)
      static.render(buffer, x: 0, y: 0, width: 10, height: 1)

      expect(buffer[0, 0].symbol).to eq("日")
      expect(buffer[2, 0].symbol).to eq("本")
      expect(buffer[4, 0].symbol).to eq("語")
    end

    it "renders button with emoji label" do
      button = Ratatat::Button.new("🚀Go")
      buffer = Ratatat::Buffer.new(10, 1)
      button.render(buffer, x: 0, y: 0, width: 10, height: 1)

      # Button format: [ label ]
      # Should contain the emoji and text
      row = (0...10).map { |i| buffer[i, 0].symbol }.join
      expect(row).to include("🚀")
      expect(row).to include("Go")
    end
  end
end
