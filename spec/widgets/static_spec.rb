# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Static do
  it "stores text content" do
    static = Ratatat::Static.new("Hello, World!")
    expect(static.text).to eq("Hello, World!")
  end

  it "has reactive text property" do
    static = Ratatat::Static.new("Initial")
    static.text = "Updated"
    expect(static.text).to eq("Updated")
  end

  it "renders text to buffer" do
    static = Ratatat::Static.new("Hi")
    buffer = Ratatat::Buffer.new(10, 1)
    static.render(buffer, x: 0, y: 0, width: 10, height: 1)

    expect(buffer[0, 0].symbol).to eq("H")
    expect(buffer[1, 0].symbol).to eq("i")
  end

  it "truncates text that exceeds width" do
    static = Ratatat::Static.new("Hello, World!")
    buffer = Ratatat::Buffer.new(5, 1)
    static.render(buffer, x: 0, y: 0, width: 5, height: 1)

    expect(buffer[0, 0].symbol).to eq("H")
    expect(buffer[4, 0].symbol).to eq("o")
  end

  it "cannot receive focus" do
    static = Ratatat::Static.new("Text")
    expect(static.can_focus?).to be false
  end
end
