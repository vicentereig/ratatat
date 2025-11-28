# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Tooltip do
  it "stores tooltip text" do
    tooltip = Ratatat::Tooltip.new(text: "Helpful hint")
    expect(tooltip.text).to eq("Helpful hint")
  end

  it "cannot receive focus" do
    tooltip = Ratatat::Tooltip.new(text: "Test")
    expect(tooltip.can_focus?).to be false
  end

  it "is hidden by default" do
    tooltip = Ratatat::Tooltip.new(text: "Test")
    expect(tooltip.visible).to be false
  end

  it "can be shown and hidden" do
    tooltip = Ratatat::Tooltip.new(text: "Test")

    tooltip.show
    expect(tooltip.visible).to be true

    tooltip.hide
    expect(tooltip.visible).to be false
  end

  it "can be positioned" do
    tooltip = Ratatat::Tooltip.new(text: "Test", anchor_x: 10, anchor_y: 5)
    expect(tooltip.anchor_x).to eq(10)
    expect(tooltip.anchor_y).to eq(5)
  end

  it "renders text in a box when visible" do
    tooltip = Ratatat::Tooltip.new(text: "Hello")
    tooltip.show

    buffer = Ratatat::Buffer.new(15, 3)
    tooltip.render(buffer, x: 0, y: 0, width: 15, height: 3)

    row1 = (0...15).map { |i| buffer[i, 1].symbol }.join
    expect(row1).to include("Hello")
  end

  it "does not render when hidden" do
    tooltip = Ratatat::Tooltip.new(text: "Secret")

    buffer = Ratatat::Buffer.new(15, 3)
    tooltip.render(buffer, x: 0, y: 0, width: 15, height: 3)

    all_content = (0...3).map do |y|
      (0...15).map { |i| buffer[i, y].symbol }.join
    end.join

    expect(all_content).not_to include("Secret")
  end

  it "renders with border" do
    tooltip = Ratatat::Tooltip.new(text: "Tip")
    tooltip.show

    buffer = Ratatat::Buffer.new(10, 3)
    tooltip.render(buffer, x: 0, y: 0, width: 10, height: 3)

    row0 = (0...10).map { |i| buffer[i, 0].symbol }.join
    row2 = (0...10).map { |i| buffer[i, 2].symbol }.join

    # Should have border characters
    expect(row0).to include("─")
    expect(row2).to include("─")
  end
end
