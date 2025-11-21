require "spec_helper"

RSpec.describe Ratatat::Widgets::List do
  it "renders up to the available rows with a cursor marker" do
    lines = (1..5).map { |i| "line #{i}" }
    widget = described_class.new(lines: lines, cursor: 2)

    rendered = widget.render(rows: 3, cols: 20)

    expect(rendered.length).to eq(3)
    expect(rendered[0]).to eq("  line 1")
    expect(rendered[1]).to eq("> line 2")
    expect(rendered[2]).to eq("  line 3")
  end

  it "scrolls when cursor falls outside the window" do
    lines = (1..10).map { |i| "line #{i}" }
    widget = described_class.new(lines: lines, cursor: 7)

    rendered = widget.render(rows: 4, cols: 15)

    expect(rendered.first).to include("line 6")
    expect(rendered[1]).to start_with("> line 7")
    expect(rendered.last).to include("line 9")
  end
end
