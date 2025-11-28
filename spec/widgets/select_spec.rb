# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Select do
  it "stores options" do
    select = Ratatat::Select.new(options: ["Red", "Green", "Blue"])
    expect(select.options).to eq(["Red", "Green", "Blue"])
  end

  it "has a selected index" do
    select = Ratatat::Select.new(options: ["A", "B", "C"], selected: 1)
    expect(select.selected).to eq(1)
    expect(select.selected_option).to eq("B")
  end

  it "defaults to first option" do
    select = Ratatat::Select.new(options: ["A", "B"])
    expect(select.selected).to eq(0)
  end

  it "can receive focus" do
    select = Ratatat::Select.new(options: ["A"])
    expect(select.can_focus?).to be true
  end

  it "navigates with up/down arrows" do
    app = Ratatat::App.new
    select = Ratatat::Select.new(options: ["A", "B", "C"])
    app.mount(select)
    select.focus

    expect(select.selected).to eq(0)

    select.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(select.selected).to eq(1)

    select.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(select.selected).to eq(2)

    select.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(select.selected).to eq(1)
  end

  it "wraps around at boundaries" do
    app = Ratatat::App.new
    select = Ratatat::Select.new(options: ["A", "B", "C"])
    app.mount(select)
    select.focus

    select.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(select.selected).to eq(2)

    select.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(select.selected).to eq(0)
  end

  it "emits Changed message when selection changes" do
    app = Ratatat::App.new
    select = Ratatat::Select.new(options: ["A", "B", "C"], id: "sel")
    changed_index = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_select_changed) do |msg|
        changed_index = msg.selected
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(select)
    select.focus

    select.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))

    expect(changed_index).to eq(1)
  end

  it "renders current selection" do
    select = Ratatat::Select.new(options: ["Apple", "Banana", "Cherry"], selected: 1)
    buffer = Ratatat::Buffer.new(20, 1)
    select.render(buffer, x: 0, y: 0, width: 20, height: 1)

    content = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(content).to include("Banana")
  end
end

RSpec.describe Ratatat::SelectionList do
  it "renders all options with highlight" do
    list = Ratatat::SelectionList.new(options: ["A", "B", "C"], selected: 1)
    buffer = Ratatat::Buffer.new(10, 3)
    list.render(buffer, x: 0, y: 0, width: 10, height: 3)

    # First row should have A
    row0 = (0...10).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("A")

    # Second row should have B with marker
    row1 = (0...10).map { |i| buffer[i, 1].symbol }.join
    expect(row1).to include("B")
    expect(row1).to include(">")
  end
end
