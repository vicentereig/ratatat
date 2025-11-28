# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::RadioSet do
  it "stores options" do
    radio = Ratatat::RadioSet.new(options: ["A", "B", "C"])
    expect(radio.options).to eq(["A", "B", "C"])
  end

  it "has single selected option" do
    radio = Ratatat::RadioSet.new(options: ["A", "B", "C"], selected: 1)
    expect(radio.selected).to eq(1)
    expect(radio.selected_option).to eq("B")
  end

  it "can receive focus" do
    radio = Ratatat::RadioSet.new(options: ["A"])
    expect(radio.can_focus?).to be true
  end

  it "navigates with up/down" do
    app = Ratatat::App.new
    radio = Ratatat::RadioSet.new(options: ["A", "B", "C"])
    app.mount(radio)
    radio.focus

    radio.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(radio.selected).to eq(1)

    radio.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(radio.selected).to eq(2)

    radio.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(radio.selected).to eq(1)
  end

  it "selects with Space or Enter" do
    app = Ratatat::App.new
    radio = Ratatat::RadioSet.new(options: ["A", "B", "C"])
    changed_to = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_radioset_changed) do |msg|
        changed_to = msg.selected
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(radio)
    radio.focus

    radio.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    radio.dispatch(Ratatat::Key.new(sender: app, key: " ", modifiers: Set.new))

    expect(changed_to).to eq(1)
  end

  it "renders with radio buttons" do
    radio = Ratatat::RadioSet.new(options: ["Yes", "No"], selected: 0)
    buffer = Ratatat::Buffer.new(15, 2)
    radio.render(buffer, x: 0, y: 0, width: 15, height: 2)

    row0 = (0...15).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("(*)") # Selected
    expect(row0).to include("Yes")

    row1 = (0...15).map { |i| buffer[i, 1].symbol }.join
    expect(row1).to include("( )") # Not selected
    expect(row1).to include("No")
  end
end
