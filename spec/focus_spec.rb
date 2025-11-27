# typed: false
require_relative "spec_helper"

class FocusableWidget < Ratatat::Widget
  CAN_FOCUS = true
end

class NonFocusableWidget < Ratatat::Widget
  CAN_FOCUS = false
end

RSpec.describe "Focus System" do
  describe "App#focused" do
    it "starts with no focus" do
      app = Ratatat::App.new
      expect(app.focused).to be_nil
    end

    it "tracks focused widget" do
      app = Ratatat::App.new
      widget = FocusableWidget.new(id: "input")
      app.mount(widget)

      widget.focus
      expect(app.focused).to eq(widget)
    end
  end

  describe "Widget#focus" do
    it "sets focus on focusable widget" do
      app = Ratatat::App.new
      widget = FocusableWidget.new
      app.mount(widget)

      widget.focus
      expect(widget.has_focus?).to eq(true)
    end

    it "does nothing on non-focusable widget" do
      app = Ratatat::App.new
      widget = NonFocusableWidget.new
      app.mount(widget)

      widget.focus
      expect(widget.has_focus?).to eq(false)
    end

    it "removes focus from previous widget" do
      app = Ratatat::App.new
      w1 = FocusableWidget.new(id: "w1")
      w2 = FocusableWidget.new(id: "w2")
      app.mount(w1, w2)

      w1.focus
      expect(w1.has_focus?).to eq(true)

      w2.focus
      expect(w1.has_focus?).to eq(false)
      expect(w2.has_focus?).to eq(true)
    end
  end

  describe "Widget#blur" do
    it "removes focus" do
      app = Ratatat::App.new
      widget = FocusableWidget.new
      app.mount(widget)

      widget.focus
      widget.blur
      expect(widget.has_focus?).to eq(false)
      expect(app.focused).to be_nil
    end
  end

  describe "Tab navigation" do
    it "moves focus to next focusable widget" do
      app = Ratatat::App.new
      w1 = FocusableWidget.new(id: "w1")
      w2 = FocusableWidget.new(id: "w2")
      w3 = FocusableWidget.new(id: "w3")
      app.mount(w1, w2, w3)

      w1.focus
      app.focus_next

      expect(w2.has_focus?).to eq(true)
    end

    it "wraps around to first widget" do
      app = Ratatat::App.new
      w1 = FocusableWidget.new(id: "w1")
      w2 = FocusableWidget.new(id: "w2")
      app.mount(w1, w2)

      w2.focus
      app.focus_next

      expect(w1.has_focus?).to eq(true)
    end

    it "skips non-focusable widgets" do
      app = Ratatat::App.new
      w1 = FocusableWidget.new(id: "w1")
      skip = NonFocusableWidget.new(id: "skip")
      w2 = FocusableWidget.new(id: "w2")
      app.mount(w1, skip, w2)

      w1.focus
      app.focus_next

      expect(w2.has_focus?).to eq(true)
    end

    it "focuses first widget when none focused" do
      app = Ratatat::App.new
      w1 = FocusableWidget.new(id: "w1")
      w2 = FocusableWidget.new(id: "w2")
      app.mount(w1, w2)

      app.focus_next

      expect(w1.has_focus?).to eq(true)
    end
  end

  describe "Shift+Tab navigation" do
    it "moves focus to previous focusable widget" do
      app = Ratatat::App.new
      w1 = FocusableWidget.new(id: "w1")
      w2 = FocusableWidget.new(id: "w2")
      w3 = FocusableWidget.new(id: "w3")
      app.mount(w1, w2, w3)

      w2.focus
      app.focus_previous

      expect(w1.has_focus?).to eq(true)
    end

    it "wraps around to last widget" do
      app = Ratatat::App.new
      w1 = FocusableWidget.new(id: "w1")
      w2 = FocusableWidget.new(id: "w2")
      app.mount(w1, w2)

      w1.focus
      app.focus_previous

      expect(w2.has_focus?).to eq(true)
    end
  end

  describe "nested focus" do
    it "finds focusable descendants" do
      app = Ratatat::App.new
      container = NonFocusableWidget.new(id: "container")
      nested = FocusableWidget.new(id: "nested")
      container.mount(nested)
      app.mount(container)

      app.focus_next

      expect(nested.has_focus?).to eq(true)
    end
  end
end
