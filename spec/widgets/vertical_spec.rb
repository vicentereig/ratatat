# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Vertical do
  it "lays out children vertically" do
    v = Ratatat::Vertical.new
    v.mount(
      Ratatat::Static.new("A"),
      Ratatat::Static.new("B"),
      Ratatat::Static.new("C")
    )

    expect(v.children.length).to eq(3)
  end

  it "divides height equally by default" do
    v = Ratatat::Vertical.new
    v.mount(
      Ratatat::Static.new("Top"),
      Ratatat::Static.new("Bottom")
    )

    buffer = Ratatat::Buffer.new(10, 4)
    v.render(buffer, x: 0, y: 0, width: 10, height: 4)

    # First child gets rows 0-1, second gets rows 2-3
    top_row = (0...10).map { |i| buffer[i, 0].symbol }.join
    bottom_row = (0...10).map { |i| buffer[i, 2].symbol }.join

    expect(top_row).to include("Top")
    expect(bottom_row).to include("Bottom")
  end

  it "supports gap between children" do
    v = Ratatat::Vertical.new(gap: 1)
    v.mount(
      Ratatat::Static.new("A"),
      Ratatat::Static.new("B")
    )

    expect(v.gap).to eq(1)
  end

  it "supports custom ratios" do
    v = Ratatat::Vertical.new(ratios: [0.25, 0.75])
    v.mount(
      Ratatat::Static.new("Header"),
      Ratatat::Static.new("Content")
    )

    expect(v.ratios).to eq([0.25, 0.75])
  end

  it "cannot receive focus" do
    v = Ratatat::Vertical.new
    expect(v.can_focus?).to be false
  end

  it "renders children at correct y positions" do
    v = Ratatat::Vertical.new
    v.mount(
      Ratatat::Static.new("One"),
      Ratatat::Static.new("Two"),
      Ratatat::Static.new("Three")
    )

    buffer = Ratatat::Buffer.new(10, 3)
    v.render(buffer, x: 0, y: 0, width: 10, height: 3)

    row0 = (0...10).map { |i| buffer[i, 0].symbol }.join
    row1 = (0...10).map { |i| buffer[i, 1].symbol }.join
    row2 = (0...10).map { |i| buffer[i, 2].symbol }.join

    expect(row0).to include("One")
    expect(row1).to include("Two")
    expect(row2).to include("Three")
  end
end
