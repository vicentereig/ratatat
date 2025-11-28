# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Log do
  it "stores log lines" do
    log = Ratatat::Log.new
    log.write("Line 1")
    log.write("Line 2")

    expect(log.lines).to eq(["Line 1", "Line 2"])
  end

  it "auto-scrolls to bottom by default" do
    log = Ratatat::Log.new(auto_scroll: true)
    10.times { |i| log.write("Line #{i}") }

    expect(log.auto_scroll).to be true
  end

  it "can scroll with up/down when focused" do
    app = Ratatat::App.new
    log = Ratatat::Log.new
    10.times { |i| log.write("Line #{i}") }
    app.mount(log)
    log.focus

    initial_scroll = log.scroll_offset
    log.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))

    expect(log.scroll_offset).to be < initial_scroll
  end

  it "can receive focus" do
    log = Ratatat::Log.new
    expect(log.can_focus?).to be true
  end

  it "renders visible lines" do
    log = Ratatat::Log.new
    log.write("First")
    log.write("Second")
    log.write("Third")

    buffer = Ratatat::Buffer.new(10, 2)
    log.render(buffer, x: 0, y: 0, width: 10, height: 2)

    # Should show last 2 lines when auto-scrolled
    row0 = (0...10).map { |i| buffer[i, 0].symbol }.join
    row1 = (0...10).map { |i| buffer[i, 1].symbol }.join

    expect(row0).to include("Second")
    expect(row1).to include("Third")
  end

  it "respects max_lines" do
    log = Ratatat::Log.new(max_lines: 3)
    5.times { |i| log.write("Line #{i}") }

    expect(log.lines.length).to eq(3)
    expect(log.lines.first).to eq("Line 2")
  end

  it "clears log" do
    log = Ratatat::Log.new
    log.write("Test")
    log.clear

    expect(log.lines).to be_empty
  end

  it "supports write_line alias" do
    log = Ratatat::Log.new
    log.write_line("Hello")

    expect(log.lines).to eq(["Hello"])
  end
end
