require "spec_helper"

class DummyWidget
  def initialize(label)
    @label = label
  end

  def render(rows:, cols:)
    [(@label * cols)[0, cols]] * rows
  end
end

RSpec.describe Ratatat::Widgets::Split do
  it "splits available width evenly by default" do
    split = described_class.new(
      left: DummyWidget.new("L"),
      right: DummyWidget.new("R")
    )

    lines = split.render(rows: 1, cols: 11) # 10 chars + separator

    expect(lines.first.length).to eq(11)
    expect(lines.first[0, 5]).to eq("LLLLL") # 5 left (available 10 / 2)
    expect(lines.first[5]).to eq("│")
    expect(lines.first[6, 5]).to eq("RRRRR")
  end
end
