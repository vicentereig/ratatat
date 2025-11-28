# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::TreeNode do
  it "stores label and children" do
    node = Ratatat::TreeNode.new("Root", [
      Ratatat::TreeNode.new("Child 1"),
      Ratatat::TreeNode.new("Child 2"),
    ])

    expect(node.label).to eq("Root")
    expect(node.children.length).to eq(2)
  end

  it "is expandable if has children" do
    parent = Ratatat::TreeNode.new("Parent", [Ratatat::TreeNode.new("Child")])
    leaf = Ratatat::TreeNode.new("Leaf")

    expect(parent.expandable?).to be true
    expect(leaf.expandable?).to be false
  end

  it "starts collapsed" do
    node = Ratatat::TreeNode.new("Root", [Ratatat::TreeNode.new("Child")])
    expect(node.expanded).to be false
  end
end

RSpec.describe Ratatat::Tree do
  it "stores root nodes" do
    tree = Ratatat::Tree.new(roots: [
      Ratatat::TreeNode.new("A"),
      Ratatat::TreeNode.new("B"),
    ])

    expect(tree.roots.length).to eq(2)
  end

  it "can receive focus" do
    tree = Ratatat::Tree.new(roots: [Ratatat::TreeNode.new("A")])
    expect(tree.can_focus?).to be true
  end

  it "navigates with up/down" do
    tree = Ratatat::Tree.new(roots: [
      Ratatat::TreeNode.new("A"),
      Ratatat::TreeNode.new("B"),
      Ratatat::TreeNode.new("C"),
    ])

    app = Ratatat::App.new
    app.mount(tree)
    tree.focus

    expect(tree.cursor).to eq(0)

    tree.dispatch(Ratatat::Key.new(sender: app, key: "down", modifiers: Set.new))
    expect(tree.cursor).to eq(1)

    tree.dispatch(Ratatat::Key.new(sender: app, key: "up", modifiers: Set.new))
    expect(tree.cursor).to eq(0)
  end

  it "expands/collapses with Enter or right/left" do
    child = Ratatat::TreeNode.new("Child")
    parent = Ratatat::TreeNode.new("Parent", [child])
    tree = Ratatat::Tree.new(roots: [parent])

    app = Ratatat::App.new
    app.mount(tree)
    tree.focus

    expect(parent.expanded).to be false

    tree.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))
    expect(parent.expanded).to be true

    tree.dispatch(Ratatat::Key.new(sender: app, key: "enter", modifiers: Set.new))
    expect(parent.expanded).to be false

    tree.dispatch(Ratatat::Key.new(sender: app, key: "right", modifiers: Set.new))
    expect(parent.expanded).to be true

    tree.dispatch(Ratatat::Key.new(sender: app, key: "left", modifiers: Set.new))
    expect(parent.expanded).to be false
  end

  it "renders tree structure" do
    tree = Ratatat::Tree.new(roots: [
      Ratatat::TreeNode.new("Root", [
        Ratatat::TreeNode.new("Child"),
      ]),
    ])
    tree.roots.first.expanded = true

    buffer = Ratatat::Buffer.new(20, 3)
    tree.render(buffer, x: 0, y: 0, width: 20, height: 3)

    row0 = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row0).to include("Root")

    row1 = (0...20).map { |i| buffer[i, 1].symbol }.join
    expect(row1).to include("Child")
  end

  it "emits NodeSelected message" do
    tree = Ratatat::Tree.new(roots: [Ratatat::TreeNode.new("A", data: { id: 1 })])
    selected_data = nil

    handler_class = Class.new(Ratatat::Widget) do
      define_method(:on_tree_nodeselected) do |msg|
        selected_data = msg.node.data
      end
    end

    app = Ratatat::App.new
    handler = handler_class.new
    app.mount(handler)
    handler.mount(tree)
    tree.focus

    tree.dispatch(Ratatat::Key.new(sender: app, key: " ", modifiers: Set.new))

    expect(selected_data).to eq({ id: 1 })
  end
end
