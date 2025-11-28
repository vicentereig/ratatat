# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Horizontal do
  it "lays out children horizontally" do
    h = Ratatat::Horizontal.new
    h.mount(
      Ratatat::Static.new("A"),
      Ratatat::Static.new("B"),
      Ratatat::Static.new("C")
    )

    expect(h.children.length).to eq(3)
  end

  it "divides width equally by default" do
    h = Ratatat::Horizontal.new
    h.mount(
      Ratatat::Static.new("Left"),
      Ratatat::Static.new("Right")
    )

    buffer = Ratatat::Buffer.new(10, 1)
    h.render(buffer, x: 0, y: 0, width: 10, height: 1)

    # First child gets columns 0-4, second gets 5-9
    left_part = (0...5).map { |i| buffer[i, 0].symbol }.join
    right_part = (5...10).map { |i| buffer[i, 0].symbol }.join

    expect(left_part).to include("Left")
    expect(right_part).to include("Right")
  end

  it "supports gap between children" do
    h = Ratatat::Horizontal.new(gap: 2)
    h.mount(
      Ratatat::Static.new("A"),
      Ratatat::Static.new("B")
    )

    expect(h.gap).to eq(2)
  end

  it "supports custom ratios" do
    h = Ratatat::Horizontal.new(ratios: [0.3, 0.7])
    h.mount(
      Ratatat::Static.new("Small"),
      Ratatat::Static.new("Large")
    )

    buffer = Ratatat::Buffer.new(10, 1)
    h.render(buffer, x: 0, y: 0, width: 10, height: 1)

    # First child gets ~30% (3 cols), second gets ~70% (7 cols)
    expect(h.ratios).to eq([0.3, 0.7])
  end

  it "cannot receive focus" do
    h = Ratatat::Horizontal.new
    expect(h.can_focus?).to be false
  end
end
