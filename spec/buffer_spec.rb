# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::Buffer do
  describe "creation" do
    it "creates buffer with given dimensions" do
      buffer = Ratatat::Buffer.new(80, 24)
      expect(buffer.width).to eq(80)
      expect(buffer.height).to eq(24)
      expect(buffer.cells.length).to eq(80 * 24)
    end

    it "fills with empty cells" do
      buffer = Ratatat::Buffer.new(10, 5)
      expect(buffer.get(0, 0).symbol).to eq(" ")
      expect(buffer.get(9, 4).symbol).to eq(" ")
    end
  end

  describe "#get and #set" do
    it "reads and writes cells" do
      buffer = Ratatat::Buffer.new(10, 5)
      cell = Ratatat::Cell.new(symbol: "X", fg: Ratatat::Color::Named::Red)

      buffer.set(3, 2, cell)
      retrieved = buffer.get(3, 2)

      expect(retrieved.symbol).to eq("X")
      expect(retrieved.fg).to eq(Ratatat::Color::Named::Red)
    end

    it "returns nil for out of bounds" do
      buffer = Ratatat::Buffer.new(10, 5)
      expect(buffer.get(-1, 0)).to be_nil
      expect(buffer.get(10, 0)).to be_nil
      expect(buffer.get(0, 5)).to be_nil
    end
  end

  describe "#put_string" do
    it "writes string to buffer" do
      buffer = Ratatat::Buffer.new(20, 5)
      buffer.put_string(5, 2, "Hello")

      expect(buffer.get(5, 2).symbol).to eq("H")
      expect(buffer.get(6, 2).symbol).to eq("e")
      expect(buffer.get(7, 2).symbol).to eq("l")
      expect(buffer.get(8, 2).symbol).to eq("l")
      expect(buffer.get(9, 2).symbol).to eq("o")
    end

    it "applies styling" do
      buffer = Ratatat::Buffer.new(20, 5)
      buffer.put_string(0, 0, "Hi", fg: Ratatat::Color::Named::Red)

      expect(buffer.get(0, 0).fg).to eq(Ratatat::Color::Named::Red)
      expect(buffer.get(1, 0).fg).to eq(Ratatat::Color::Named::Red)
    end

    it "truncates at buffer edge" do
      buffer = Ratatat::Buffer.new(5, 1)
      buffer.put_string(3, 0, "Hello")

      expect(buffer.get(3, 0).symbol).to eq("H")
      expect(buffer.get(4, 0).symbol).to eq("e")
      # No overflow
    end
  end

  describe "#to_text" do
    it "renders buffer content as string" do
      buffer = Ratatat::Buffer.new(10, 2)
      buffer.put_string(0, 0, "Hello")
      buffer.put_string(0, 1, "World")

      text = buffer.to_text
      expect(text).to eq("Hello\nWorld")
    end
  end

  describe "#clear" do
    it "resets all cells to empty" do
      buffer = Ratatat::Buffer.new(10, 5)
      buffer.put_string(0, 0, "Test")
      buffer.clear

      expect(buffer.get(0, 0).symbol).to eq(" ")
      expect(buffer.get(1, 0).symbol).to eq(" ")
    end
  end

  describe "#diff" do
    it "returns empty for identical buffers" do
      buffer1 = Ratatat::Buffer.new(10, 5)
      buffer2 = Ratatat::Buffer.new(10, 5)

      diff = buffer1.diff(buffer2)
      expect(diff).to be_empty
    end

    it "returns changed cells" do
      buffer1 = Ratatat::Buffer.new(10, 5)
      buffer2 = Ratatat::Buffer.new(10, 5)
      buffer2.put_string(0, 0, "X")

      diff = buffer1.diff(buffer2)

      expect(diff.length).to eq(1)
      expect(diff[0][0]).to eq(0)  # x
      expect(diff[0][1]).to eq(0)  # y
      expect(diff[0][2].symbol).to eq("X")
    end

    it "detects multiple changes" do
      buffer1 = Ratatat::Buffer.new(10, 5)
      buffer2 = Ratatat::Buffer.new(10, 5)
      buffer2.put_string(0, 0, "AB")
      buffer2.put_string(5, 3, "CD")

      diff = buffer1.diff(buffer2)
      expect(diff.length).to eq(4)  # A, B, C, D
    end

    it "detects color changes" do
      buffer1 = Ratatat::Buffer.new(10, 5)
      buffer2 = Ratatat::Buffer.new(10, 5)

      buffer1.put_string(0, 0, "X")
      buffer2.put_string(0, 0, "X", fg: Ratatat::Color::Named::Red)

      diff = buffer1.diff(buffer2)
      expect(diff.length).to eq(1)
      expect(diff[0][2].fg).to eq(Ratatat::Color::Named::Red)
    end

    it "raises for mismatched buffer sizes" do
      buffer1 = Ratatat::Buffer.new(10, 5)
      buffer2 = Ratatat::Buffer.new(20, 10)

      expect { buffer1.diff(buffer2) }.to raise_error(ArgumentError, /size mismatch/)
    end

    it "skips cells marked with skip flag" do
      buffer1 = Ratatat::Buffer.new(10, 5)
      buffer2 = Ratatat::Buffer.new(10, 5)

      buffer2.set(0, 0, Ratatat::Cell.new(symbol: "X", skip: true))

      diff = buffer1.diff(buffer2)
      expect(diff).to be_empty
    end
  end

  describe "#resize" do
    it "preserves content when growing" do
      buffer = Ratatat::Buffer.new(5, 3)
      buffer.put_string(0, 0, "Test")

      buffer.resize(10, 5)

      expect(buffer.width).to eq(10)
      expect(buffer.height).to eq(5)
      expect(buffer.get(0, 0).symbol).to eq("T")
      expect(buffer.get(1, 0).symbol).to eq("e")
    end

    it "truncates content when shrinking" do
      buffer = Ratatat::Buffer.new(10, 5)
      buffer.put_string(0, 0, "Hello World")

      buffer.resize(5, 2)

      expect(buffer.width).to eq(5)
      expect(buffer.height).to eq(2)
      expect(buffer.get(0, 0).symbol).to eq("H")
      expect(buffer.get(4, 0).symbol).to eq("o")
    end
  end

  describe "index conversion" do
    it "converts (x, y) to linear index" do
      buffer = Ratatat::Buffer.new(10, 5)
      expect(buffer.index_of(3, 2)).to eq(23)  # 2 * 10 + 3
    end

    it "converts linear index to (x, y)" do
      buffer = Ratatat::Buffer.new(10, 5)
      expect(buffer.pos_of(23)).to eq([3, 2])
    end
  end
end
