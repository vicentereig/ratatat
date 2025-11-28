# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Checkbox do
  it "stores checked state" do
    checkbox = Ratatat::Checkbox.new("Accept terms")
    expect(checkbox.checked).to be false

    checkbox.checked = true
    expect(checkbox.checked).to be true
  end

  it "stores label" do
    checkbox = Ratatat::Checkbox.new("Accept terms")
    expect(checkbox.label).to eq("Accept terms")
  end

  it "can receive focus" do
    checkbox = Ratatat::Checkbox.new("Option")
    expect(checkbox.can_focus?).to be true
  end

  it "toggles on Space" do
    app = Ratatat::App.new
    checkbox = Ratatat::Checkbox.new("Option")
    app.mount(checkbox)
    checkbox.focus

    expect(checkbox.checked).to be false
    checkbox.dispatch(Ratatat::Key.new(sender: app, key: " ", modifiers: Set.new))
    expect(checkbox.checked).to be true
    checkbox.dispatch(Ratatat::Key.new(sender: app, key: " ", modifiers: Set.new))
    expect(checkbox.checked).to be false
  end

  it "toggles on Enter" do
    app = Ratatat::App.new
    checkbox = Ratatat::Checkbox.new("Option")
    app.mount(checkbox)
    checkbox.focus

    checkbox.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))
    expect(checkbox.checked).to be true
  end

  it "emits Changed message when toggled" do
    app = Ratatat::App.new
    checkbox = Ratatat::Checkbox.new("Option", id: "cb")
    changed_value = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_checkbox_changed) do |msg|
        changed_value = msg.checked
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(checkbox)
    checkbox.focus

    checkbox.dispatch(Ratatat::Key.new(sender: app, key: " ", modifiers: Set.new))

    expect(changed_value).to be true
  end

  it "renders unchecked state" do
    checkbox = Ratatat::Checkbox.new("Option")
    buffer = Ratatat::Buffer.new(20, 1)
    checkbox.render(buffer, x: 0, y: 0, width: 20, height: 1)

    content = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(content).to include("[ ]")
    expect(content).to include("Option")
  end

  it "renders checked state" do
    checkbox = Ratatat::Checkbox.new("Option", checked: true)
    buffer = Ratatat::Buffer.new(20, 1)
    checkbox.render(buffer, x: 0, y: 0, width: 20, height: 1)

    content = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(content).to include("[X]")
  end
end

RSpec.describe Ratatat::Switch do
  it "is a toggle with different rendering" do
    switch = Ratatat::Switch.new("Dark mode")
    expect(switch.checked).to be false
    expect(switch.label).to eq("Dark mode")
  end

  it "renders off state" do
    switch = Ratatat::Switch.new("Option")
    buffer = Ratatat::Buffer.new(20, 1)
    switch.render(buffer, x: 0, y: 0, width: 20, height: 1)

    content = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(content).to include("OFF")
  end

  it "renders on state" do
    switch = Ratatat::Switch.new("Option", checked: true)
    buffer = Ratatat::Buffer.new(20, 1)
    switch.render(buffer, x: 0, y: 0, width: 20, height: 1)

    content = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(content).to include("ON")
  end
end
