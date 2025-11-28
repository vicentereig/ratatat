# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::DataTable do
  it "stores columns and rows" do
    table = Ratatat::DataTable.new(
      columns: ["Name", "Age", "City"],
      rows: [
        ["Alice", "30", "NYC"],
        ["Bob", "25", "LA"],
      ]
    )

    expect(table.columns).to eq(["Name", "Age", "City"])
    expect(table.rows.length).to eq(2)
  end

  it "can receive focus" do
    table = Ratatat::DataTable.new(columns: ["A"], rows: [["1"]])
    expect(table.can_focus?).to be true
  end

  it "tracks cursor row" do
    table = Ratatat::DataTable.new(
      columns: ["Name"],
      rows: [["A"], ["B"], ["C"]]
    )

    expect(table.cursor_row).to eq(0)
  end

  it "navigates rows with up/down" do
    app = Ratatat::App.new
    table = Ratatat::DataTable.new(
      columns: ["Name"],
      rows: [["A"], ["B"], ["C"]]
    )
    app.mount(table)
    table.focus

    table.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(table.cursor_row).to eq(1)

    table.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(table.cursor_row).to eq(2)

    table.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(table.cursor_row).to eq(1)
  end

  it "emits RowSelected on Enter" do
    app = Ratatat::App.new
    table = Ratatat::DataTable.new(
      columns: ["Name"],
      rows: [["Alice"], ["Bob"]],
      id: "tbl"
    )
    selected_row = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_datatable_rowselected) do |msg|
        selected_row = msg.row
      end
    end

    handler = handler_class.new
    app.mount(handler)
    handler.mount(table)
    table.focus

    table.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    table.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))

    expect(selected_row).to eq(["Bob"])
  end

  it "renders header and rows" do
    table = Ratatat::DataTable.new(
      columns: ["Name", "Age"],
      rows: [["Alice", "30"], ["Bob", "25"]]
    )
    buffer = Ratatat::Buffer.new(20, 4)
    table.render(buffer, x: 0, y: 0, width: 20, height: 4)

    # Header row
    row0 = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("Name")
    expect(row0).to include("Age")

    # Data rows
    row1 = (0...20).map { |i| buffer[i, 1].symbol }.join
    expect(row1).to include("Alice")

    row2 = (0...20).map { |i| buffer[i, 2].symbol }.join
    expect(row2).to include("Bob")
  end

  it "adds rows dynamically" do
    table = Ratatat::DataTable.new(columns: ["A"], rows: [])
    table.add_row(["1"])
    table.add_row(["2"])

    expect(table.rows.length).to eq(2)
  end

  it "clears rows" do
    table = Ratatat::DataTable.new(columns: ["A"], rows: [["1"], ["2"]])
    table.clear_rows

    expect(table.rows).to be_empty
  end
end
