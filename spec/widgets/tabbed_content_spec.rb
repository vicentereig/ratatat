# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::TabbedContent do
  it "stores tabs with labels" do
    tabs = Ratatat::TabbedContent.new
    tabs.add_tab("Tab 1", Ratatat::Static.new("Content 1"))
    tabs.add_tab("Tab 2", Ratatat::Static.new("Content 2"))

    expect(tabs.tab_count).to eq(2)
  end

  it "has initial active tab" do
    tabs = Ratatat::TabbedContent.new
    tabs.add_tab("Tab 1", Ratatat::Static.new("Content 1"))
    tabs.add_tab("Tab 2", Ratatat::Static.new("Content 2"))

    expect(tabs.active_tab).to eq(0)
    expect(tabs.active_label).to eq("Tab 1")
  end

  it "can receive focus" do
    tabs = Ratatat::TabbedContent.new
    expect(tabs.can_focus?).to be true
  end

  it "switches tabs with left/right" do
    app = Ratatat::App.new
    tabs = Ratatat::TabbedContent.new
    tabs.add_tab("Tab 1", Ratatat::Static.new("A"))
    tabs.add_tab("Tab 2", Ratatat::Static.new("B"))
    tabs.add_tab("Tab 3", Ratatat::Static.new("C"))
    app.mount(tabs)
    tabs.focus

    expect(tabs.active_tab).to eq(0)

    tabs.dispatch(Ratatat::Key.new(sender: app, key: "right", modifiers: Set.new))
    expect(tabs.active_tab).to eq(1)

    tabs.dispatch(Ratatat::Key.new(sender: app, key: "right", modifiers: Set.new))
    expect(tabs.active_tab).to eq(2)

    tabs.dispatch(Ratatat::Key.new(sender: app, key: "left", modifiers: Set.new))
    expect(tabs.active_tab).to eq(1)
  end

  it "emits TabChanged message on switch" do
    app = Ratatat::App.new
    tabs = Ratatat::TabbedContent.new
    changed_to = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_tabbedcontent_tabchanged) do |msg|
        changed_to = msg.index
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(tabs)

    tabs.add_tab("Tab 1", Ratatat::Static.new("A"))
    tabs.add_tab("Tab 2", Ratatat::Static.new("B"))
    tabs.focus

    tabs.dispatch(Ratatat::Key.new(sender: app, key: "right", modifiers: Set.new))

    expect(changed_to).to eq(1)
  end

  it "renders tab bar and content" do
    tabs = Ratatat::TabbedContent.new
    tabs.add_tab("One", Ratatat::Static.new("First"))
    tabs.add_tab("Two", Ratatat::Static.new("Second"))

    buffer = Ratatat::Buffer.new(20, 4)
    tabs.render(buffer, x: 0, y: 0, width: 20, height: 4)

    # Tab bar should be on first row
    row0 = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("One")
    expect(row0).to include("Two")

    # Content area should show active tab's content
    content_rows = (1...4).map do |y|
      (0...20).map { |i| buffer[i, y].symbol }.join
    end.join
    expect(content_rows).to include("First")
  end

  it "wraps tabs with Tab/Shift+Tab" do
    app = Ratatat::App.new
    tabs = Ratatat::TabbedContent.new
    tabs.add_tab("A", Ratatat::Static.new("1"))
    tabs.add_tab("B", Ratatat::Static.new("2"))
    app.mount(tabs)
    tabs.focus

    # At first tab, go left wraps to last
    tabs.dispatch(Ratatat::Key.new(sender: app, key: "left", modifiers: Set.new))
    expect(tabs.active_tab).to eq(1)

    # At last tab, go right wraps to first
    tabs.dispatch(Ratatat::Key.new(sender: app, key: "right", modifiers: Set.new))
    expect(tabs.active_tab).to eq(0)
  end

  it "can set active tab programmatically" do
    tabs = Ratatat::TabbedContent.new
    tabs.add_tab("A", Ratatat::Static.new("1"))
    tabs.add_tab("B", Ratatat::Static.new("2"))
    tabs.add_tab("C", Ratatat::Static.new("3"))

    tabs.active_tab = 2
    expect(tabs.active_tab).to eq(2)
    expect(tabs.active_label).to eq("C")
  end
end
