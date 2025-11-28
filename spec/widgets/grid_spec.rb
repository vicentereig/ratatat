# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Grid do
  it "lays out children in grid" do
    grid = Ratatat::Grid.new(columns: 2)
    grid.mount(
      Ratatat::Static.new("A"),
      Ratatat::Static.new("B"),
      Ratatat::Static.new("C"),
      Ratatat::Static.new("D")
    )

    expect(grid.children.length).to eq(4)
  end

  it "renders in rows and columns" do
    grid = Ratatat::Grid.new(columns: 2)
    grid.mount(
      Ratatat::Static.new("A"),
      Ratatat::Static.new("B"),
      Ratatat::Static.new("C"),
      Ratatat::Static.new("D")
    )

    buffer = Ratatat::Buffer.new(10, 2)
    grid.render(buffer, x: 0, y: 0, width: 10, height: 2)

    row0 = (0...10).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("A")
    expect(row0).to include("B")

    row1 = (0...10).map { |i| buffer[i, 1].symbol }.join
    expect(row1).to include("C")
    expect(row1).to include("D")
  end

  it "supports gap between cells" do
    grid = Ratatat::Grid.new(columns: 2, gap: 1)
    grid.mount(
      Ratatat::Static.new("A"),
      Ratatat::Static.new("B")
    )

    expect(grid.gap).to eq(1)
  end

  it "cannot receive focus" do
    grid = Ratatat::Grid.new(columns: 2)
    expect(grid.can_focus?).to be false
  end
end
