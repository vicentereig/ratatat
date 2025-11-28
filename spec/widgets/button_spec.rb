# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Button do
  it "stores label" do
    button = Ratatat::Button.new("Submit")
    expect(button.label).to eq("Submit")
  end

  it "can receive focus" do
    button = Ratatat::Button.new("Click")
    expect(button.can_focus?).to be true
  end

  it "emits Pressed message on Enter" do
    app = Ratatat::App.new
    button = Ratatat::Button.new("Click", id: "btn")
    pressed = false

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_button_pressed) do |msg|
        pressed = true if msg.sender.id == "btn"
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(button)
    button.focus

    button.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))

    expect(pressed).to be true
  end

  it "emits Pressed message on Space" do
    app = Ratatat::App.new
    button = Ratatat::Button.new("Click", id: "btn")
    pressed = false

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_button_pressed) do |msg|
        pressed = true
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(button)
    button.focus

    button.dispatch(Ratatat::Key.new(sender: app, key: " ", modifiers: Set.new))

    expect(pressed).to be true
  end

  it "renders label centered" do
    button = Ratatat::Button.new("OK")
    buffer = Ratatat::Buffer.new(10, 1)
    button.render(buffer, x: 0, y: 0, width: 10, height: 1)

    # "< OK >" centered in 10 chars = "  < OK >  "
    content = (0...10).map { |i| buffer[i, 0].symbol }.join
    expect(content).to include("OK")
  end
end
