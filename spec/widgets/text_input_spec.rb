# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::TextInput do
  it "stores value" do
    input = Ratatat::TextInput.new(value: "hello")
    expect(input.value).to eq("hello")
  end

  it "defaults to empty string" do
    input = Ratatat::TextInput.new
    expect(input.value).to eq("")
  end

  it "can receive focus" do
    input = Ratatat::TextInput.new
    expect(input.can_focus?).to be true
  end

  it "appends characters on keypress" do
    app = Ratatat::App.new
    input = Ratatat::TextInput.new
    app.mount(input)
    input.focus

    input.dispatch(Ratatat::Key.new(sender: app, key: "a", modifiers: Set.new))
    input.dispatch(Ratatat::Key.new(sender: app, key: "b", modifiers: Set.new))

    expect(input.value).to eq("ab")
  end

  it "handles backspace" do
    app = Ratatat::App.new
    input = Ratatat::TextInput.new(value: "abc")
    app.mount(input)
    input.focus

    input.dispatch(Ratatat::Key.new(sender: app, key: "backspace", modifiers: Set.new))

    expect(input.value).to eq("ab")
  end

  it "handles delete" do
    app = Ratatat::App.new
    input = Ratatat::TextInput.new(value: "abc")
    app.mount(input)
    input.focus

    # Move cursor to beginning then delete
    input.instance_variable_set(:@cursor, 0)
    input.dispatch(Ratatat::Key.new(sender: app, key: "delete", modifiers: Set.new))

    expect(input.value).to eq("bc")
  end

  it "moves cursor with left/right arrows" do
    app = Ratatat::App.new
    input = Ratatat::TextInput.new(value: "abc")
    app.mount(input)
    input.focus

    expect(input.cursor).to eq(3) # At end

    input.dispatch(Ratatat::Key.new(sender: app, key: "left", modifiers: Set.new))
    expect(input.cursor).to eq(2)

    input.dispatch(Ratatat::Key.new(sender: app, key: "right", modifiers: Set.new))
    expect(input.cursor).to eq(3)
  end

  it "emits Changed message when value changes" do
    app = Ratatat::App.new
    input = Ratatat::TextInput.new(id: "input")
    changed_value = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_textinput_changed) do |msg|
        changed_value = msg.value
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(input)
    input.focus

    input.dispatch(Ratatat::Key.new(sender: app, key: "x", modifiers: Set.new))

    expect(changed_value).to eq("x")
  end

  it "emits Submitted message on Enter" do
    app = Ratatat::App.new
    input = Ratatat::TextInput.new(value: "test", id: "input")
    submitted = false

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_textinput_submitted) do |msg|
        submitted = true
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(input)
    input.focus

    input.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))

    expect(submitted).to be true
  end

  it "renders value in buffer" do
    input = Ratatat::TextInput.new(value: "hello")
    buffer = Ratatat::Buffer.new(10, 1)
    input.render(buffer, x: 0, y: 0, width: 10, height: 1)

    expect(buffer[0, 0].symbol).to eq("h")
    expect(buffer[4, 0].symbol).to eq("o")
  end

  it "supports placeholder" do
    input = Ratatat::TextInput.new(placeholder: "Type here...")
    buffer = Ratatat::Buffer.new(15, 1)
    input.render(buffer, x: 0, y: 0, width: 15, height: 1)

    expect(buffer[0, 0].symbol).to eq("T")
  end
end
