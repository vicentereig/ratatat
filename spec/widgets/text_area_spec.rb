# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::TextArea do
  it "stores multi-line text" do
    area = Ratatat::TextArea.new(value: "line1\nline2\nline3")
    expect(area.value).to eq("line1\nline2\nline3")
    expect(area.lines).to eq(["line1", "line2", "line3"])
  end

  it "can receive focus" do
    area = Ratatat::TextArea.new
    expect(area.can_focus?).to be true
  end

  it "tracks cursor row and column" do
    area = Ratatat::TextArea.new(value: "hello\nworld")
    expect(area.cursor_row).to eq(0)
    expect(area.cursor_col).to eq(5) # End of first line
  end

  it "navigates with arrow keys" do
    app = Ratatat::App.new
    area = Ratatat::TextArea.new(value: "abc\ndef")
    app.mount(area)
    area.focus

    # Start at end of first line
    expect(area.cursor_row).to eq(0)
    expect(area.cursor_col).to eq(3)

    # Down arrow
    area.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(area.cursor_row).to eq(1)

    # Left arrow
    area.dispatch(Ratatat::Key.new(sender: app, key: "left", modifiers: Set.new))
    expect(area.cursor_col).to eq(2)

    # Up arrow
    area.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(area.cursor_row).to eq(0)
  end

  it "inserts characters at cursor" do
    app = Ratatat::App.new
    area = Ratatat::TextArea.new(value: "ab")
    app.mount(area)
    area.focus

    area.dispatch(Ratatat::Key.new(sender: app, key: "c", modifiers: Set.new))
    expect(area.value).to eq("abc")
  end

  it "handles Enter to insert newline" do
    app = Ratatat::App.new
    area = Ratatat::TextArea.new(value: "hello")
    app.mount(area)
    area.focus

    area.instance_variable_set(:@cursor_col, 2)
    area.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))

    expect(area.lines).to eq(["he", "llo"])
    expect(area.cursor_row).to eq(1)
    expect(area.cursor_col).to eq(0)
  end

  it "handles backspace across lines" do
    app = Ratatat::App.new
    area = Ratatat::TextArea.new(value: "abc\ndef")
    app.mount(area)
    area.focus

    area.instance_variable_set(:@cursor_row, 1)
    area.instance_variable_set(:@cursor_col, 0)

    area.dispatch(Ratatat::Key.new(sender: app, key: "backspace", modifiers: Set.new))

    expect(area.value).to eq("abcdef")
    expect(area.cursor_row).to eq(0)
    expect(area.cursor_col).to eq(3)
  end

  it "renders multiple lines" do
    area = Ratatat::TextArea.new(value: "line1\nline2")
    buffer = Ratatat::Buffer.new(10, 3)
    area.render(buffer, x: 0, y: 0, width: 10, height: 3)

    row0 = (0...10).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("line1")

    row1 = (0...10).map { |i| buffer[i, 1].symbol }.join
    expect(row1).to include("line2")
  end

  it "emits Changed message" do
    app = Ratatat::App.new
    area = Ratatat::TextArea.new(id: "ta")
    changed = false

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_textarea_changed) do |msg|
        changed = true
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(area)
    area.focus

    area.dispatch(Ratatat::Key.new(sender: app, key: "x", modifiers: Set.new))

    expect(changed).to be true
  end
end
