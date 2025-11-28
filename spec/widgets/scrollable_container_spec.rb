# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::ScrollableContainer do
  it "has virtual size larger than viewport" do
    scroll = Ratatat::ScrollableContainer.new(virtual_height: 100)
    expect(scroll.virtual_height).to eq(100)
  end

  it "can receive focus" do
    scroll = Ratatat::ScrollableContainer.new
    expect(scroll.can_focus?).to be true
  end

  it "scrolls with up/down" do
    app = Ratatat::App.new
    scroll = Ratatat::ScrollableContainer.new(virtual_height: 100)
    app.mount(scroll)
    scroll.focus

    expect(scroll.scroll_y).to eq(0)

    scroll.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(scroll.scroll_y).to eq(1)

    scroll.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(scroll.scroll_y).to eq(0)
  end

  it "clamps scroll to bounds" do
    app = Ratatat::App.new
    scroll = Ratatat::ScrollableContainer.new(virtual_height: 10)
    app.mount(scroll)
    scroll.focus

    # Try scrolling past start
    scroll.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(scroll.scroll_y).to eq(0)
  end

  it "renders children with scroll offset" do
    scroll = Ratatat::ScrollableContainer.new(virtual_height: 20)
    child = Ratatat::Static.new("Hello")
    scroll.mount(child)

    buffer = Ratatat::Buffer.new(10, 5)
    scroll.render(buffer, x: 0, y: 0, width: 10, height: 5)

    row0 = (0...10).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("Hello")
  end

  it "supports horizontal scrolling" do
    scroll = Ratatat::ScrollableContainer.new(virtual_width: 100, virtual_height: 10)
    expect(scroll.virtual_width).to eq(100)
  end
end
