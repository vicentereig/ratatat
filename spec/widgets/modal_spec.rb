# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Modal do
  it "stores title and body" do
    modal = Ratatat::Modal.new(title: "Alert", body: "Something happened!")
    expect(modal.title).to eq("Alert")
    expect(modal.body).to eq("Something happened!")
  end

  it "can receive focus" do
    modal = Ratatat::Modal.new(title: "Test")
    expect(modal.can_focus?).to be true
  end

  it "closes on Escape" do
    app = Ratatat::App.new
    modal = Ratatat::Modal.new(title: "Test", id: "modal")
    closed = false

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_modal_closed) do |msg|
        closed = true
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(modal)
    modal.focus

    modal.dispatch(Ratatat::Key.new(sender: app, key: "escape", modifiers: Set.new))

    expect(closed).to be true
  end

  it "renders border with title" do
    modal = Ratatat::Modal.new(title: "Alert", body: "Message")
    buffer = Ratatat::Buffer.new(20, 5)
    modal.render(buffer, x: 0, y: 0, width: 20, height: 5)

    row0 = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("Alert")

    row2 = (0...20).map { |i| buffer[i, 2].symbol }.join
    expect(row2).to include("Message")
  end

  it "has buttons" do
    modal = Ratatat::Modal.new(title: "Confirm", buttons: ["OK", "Cancel"])
    expect(modal.buttons).to eq(["OK", "Cancel"])
  end

  it "emits ButtonPressed with selected button" do
    app = Ratatat::App.new
    modal = Ratatat::Modal.new(title: "Confirm", buttons: ["OK", "Cancel"])
    pressed_button = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_modal_buttonpressed) do |msg|
        pressed_button = msg.button
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(modal)
    modal.focus

    # Press Enter to select first button
    modal.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))

    expect(pressed_button).to eq("OK")
  end

  it "navigates buttons with Tab" do
    app = Ratatat::App.new
    modal = Ratatat::Modal.new(title: "Confirm", buttons: ["OK", "Cancel"])
    app.mount(modal)
    modal.focus

    expect(modal.selected_button).to eq(0)

    modal.dispatch(Ratatat::Key.new(sender: app, key: "tab", modifiers: Set.new))
    expect(modal.selected_button).to eq(1)
  end
end
