# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Container do
  it "holds children" do
    container = Ratatat::Container.new
    child = Ratatat::Static.new("Child")
    container.mount(child)

    expect(container.children).to include(child)
  end

  it "cannot receive focus by default" do
    container = Ratatat::Container.new
    expect(container.can_focus?).to be false
  end
end

RSpec.describe Ratatat::Horizontal do
  it "lays out children horizontally" do
    horizontal = Ratatat::Horizontal.new
    child1 = Ratatat::Static.new("A")
    child2 = Ratatat::Static.new("B")
    horizontal.mount(child1, child2)

    buffer = Ratatat::Buffer.new(10, 1)
    horizontal.render(buffer, x: 0, y: 0, width: 10, height: 1)

    # Children should be side by side
    expect(buffer[0, 0].symbol).to eq("A")
    expect(buffer[5, 0].symbol).to eq("B")
  end
end

RSpec.describe Ratatat::Vertical do
  it "lays out children vertically" do
    vertical = Ratatat::Vertical.new
    child1 = Ratatat::Static.new("A")
    child2 = Ratatat::Static.new("B")
    vertical.mount(child1, child2)

    buffer = Ratatat::Buffer.new(5, 2)
    vertical.render(buffer, x: 0, y: 0, width: 5, height: 2)

    # Children should be stacked
    expect(buffer[0, 0].symbol).to eq("A")
    expect(buffer[0, 1].symbol).to eq("B")
  end
end
