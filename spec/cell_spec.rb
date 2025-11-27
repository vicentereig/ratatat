# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::Cell do
  describe "creation" do
    it "has default values" do
      cell = Ratatat::Cell.new
      expect(cell.symbol).to eq(" ")
      expect(cell.fg).to eq(Ratatat::Color::Named::Reset)
      expect(cell.bg).to eq(Ratatat::Color::Named::Reset)
      expect(cell.modifiers).to be_empty
      expect(cell.skip).to eq(false)
    end

    it "accepts custom values" do
      cell = Ratatat::Cell.new(
        symbol: "X",
        fg: Ratatat::Color::Named::Red,
        bg: Ratatat::Color::Named::Blue,
        modifiers: Set[Ratatat::Modifier::Bold],
        skip: true
      )
      expect(cell.symbol).to eq("X")
      expect(cell.fg).to eq(Ratatat::Color::Named::Red)
      expect(cell.bg).to eq(Ratatat::Color::Named::Blue)
      expect(cell.modifiers).to include(Ratatat::Modifier::Bold)
      expect(cell.skip).to eq(true)
    end
  end

  describe "#normalized_symbol" do
    it "returns space for empty symbol" do
      cell = Ratatat::Cell.new(symbol: "")
      expect(cell.normalized_symbol).to eq(" ")
    end

    it "returns the symbol otherwise" do
      cell = Ratatat::Cell.new(symbol: "X")
      expect(cell.normalized_symbol).to eq("X")
    end
  end

  describe "#width" do
    it "returns 1 for regular ASCII" do
      cell = Ratatat::Cell.new(symbol: "A")
      expect(cell.width).to eq(1)
    end

    it "returns 1 for empty symbol" do
      cell = Ratatat::Cell.new(symbol: "")
      expect(cell.width).to eq(1)
    end

    it "returns 2 for CJK characters" do
      cell = Ratatat::Cell.new(symbol: "\u4E2D")  # Chinese character
      expect(cell.width).to eq(2)
    end
  end

  describe "#visually_equal?" do
    it "compares symbol, colors, and modifiers" do
      cell1 = Ratatat::Cell.new(symbol: "A", fg: Ratatat::Color::Named::Red)
      cell2 = Ratatat::Cell.new(symbol: "A", fg: Ratatat::Color::Named::Red)
      cell3 = Ratatat::Cell.new(symbol: "B", fg: Ratatat::Color::Named::Red)
      cell4 = Ratatat::Cell.new(symbol: "A", fg: Ratatat::Color::Named::Blue)

      expect(cell1.visually_equal?(cell2)).to eq(true)
      expect(cell1.visually_equal?(cell3)).to eq(false)
      expect(cell1.visually_equal?(cell4)).to eq(false)
    end

    it "treats empty and space as equivalent" do
      cell1 = Ratatat::Cell.new(symbol: "")
      cell2 = Ratatat::Cell.new(symbol: " ")
      expect(cell1.visually_equal?(cell2)).to eq(true)
    end

    it "ignores skip flag" do
      cell1 = Ratatat::Cell.new(symbol: "A", skip: false)
      cell2 = Ratatat::Cell.new(symbol: "A", skip: true)
      expect(cell1.visually_equal?(cell2)).to eq(true)
    end
  end

  describe "modifier queries" do
    it "returns true when modifier present" do
      cell = Ratatat::Cell.new(modifiers: Set[Ratatat::Modifier::Bold, Ratatat::Modifier::Italic])
      expect(cell.bold?).to eq(true)
      expect(cell.italic?).to eq(true)
      expect(cell.underline?).to eq(false)
    end
  end

  describe "#with" do
    it "creates new cell with updated attributes" do
      cell = Ratatat::Cell.new(symbol: "A", fg: Ratatat::Color::Named::Red)
      new_cell = cell.with(symbol: "B")

      expect(new_cell.symbol).to eq("B")
      expect(new_cell.fg).to eq(Ratatat::Color::Named::Red)  # Preserved
      expect(cell.symbol).to eq("A")  # Original unchanged
    end
  end

  describe "EMPTY" do
    it "is a frozen empty cell" do
      expect(Ratatat::Cell::EMPTY.symbol).to eq(" ")
      expect(Ratatat::Cell::EMPTY.fg).to eq(Ratatat::Color::Named::Reset)
    end
  end
end

RSpec.describe Ratatat::Modifier do
  it "is a T::Enum" do
    expect(Ratatat::Modifier::Bold).to be_a(Ratatat::Modifier)
    expect(Ratatat::Modifier::Italic).to be_a(Ratatat::Modifier)
  end

  describe "#enable_code" do
    it "returns ANSI enable code" do
      expect(Ratatat::Modifier::Bold.enable_code).to eq(1)
      expect(Ratatat::Modifier::Italic.enable_code).to eq(3)
      expect(Ratatat::Modifier::Underline.enable_code).to eq(4)
    end

    it "returns nil for None" do
      expect(Ratatat::Modifier::None.enable_code).to be_nil
    end
  end

  describe "#disable_code" do
    it "returns ANSI disable code" do
      expect(Ratatat::Modifier::Bold.disable_code).to eq(22)
      expect(Ratatat::Modifier::Italic.disable_code).to eq(23)
    end
  end
end
