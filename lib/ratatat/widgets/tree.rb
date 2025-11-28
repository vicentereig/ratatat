# typed: strict
# frozen_string_literal: true

module Ratatat
  # A node in a tree structure
  class TreeNode
    extend T::Sig

    sig { returns(String) }
    attr_reader :label

    sig { returns(T::Array[TreeNode]) }
    attr_reader :children

    sig { returns(T.untyped) }
    attr_reader :data

    sig { returns(T::Boolean) }
    attr_accessor :expanded

    sig { params(label: String, children: T::Array[TreeNode], data: T.untyped).void }
    def initialize(label, children = [], data: nil)
      @label = label
      @children = children
      @data = data
      @expanded = T.let(false, T::Boolean)
    end

    sig { returns(T::Boolean) }
    def expandable?
      !@children.empty?
    end
  end

  # Tree view widget with expandable nodes
  class Tree < Widget
    extend T::Sig

    CAN_FOCUS = true

    # Emitted when a node is selected (Space pressed)
    class NodeSelected < Message
      extend T::Sig

      sig { returns(TreeNode) }
      attr_reader :node

      sig { params(sender: Widget, node: TreeNode).void }
      def initialize(sender:, node:)
        super(sender: sender)
        @node = node
      end
    end

    sig { returns(T::Array[TreeNode]) }
    attr_reader :roots

    reactive :cursor, default: 0, repaint: true

    sig { params(roots: T::Array[TreeNode], id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(roots: [], id: nil, classes: [])
      super(id: id, classes: classes)
      @roots = roots
      @cursor = 0
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "down", "j"
        move_cursor(1)
        message.stop
      when "up", "k"
        move_cursor(-1)
        message.stop
      when "enter"
        toggle_current
        message.stop
      when "right", "l"
        expand_current
        message.stop
      when "left", "h"
        collapse_current
        message.stop
      when " "
        select_current
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      visible = visible_nodes
      visible.each_with_index do |(node, depth), i|
        break if i >= height

        prefix = @cursor == i ? "> " : "  "
        indent = "  " * depth
        icon = if node.expandable?
                 node.expanded ? "v " : "> "
               else
                 "  "
               end
        text = "#{prefix}#{indent}#{icon}#{node.label}"
        buffer.put_string(x, y + i, text[0, width])
      end
    end

    private

    sig { returns(T::Array[[TreeNode, Integer]]) }
    def visible_nodes
      result = T.let([], T::Array[[TreeNode, Integer]])
      collect_visible(@roots, 0, result)
      result
    end

    sig { params(nodes: T::Array[TreeNode], depth: Integer, result: T::Array[[TreeNode, Integer]]).void }
    def collect_visible(nodes, depth, result)
      nodes.each do |node|
        result << [node, depth]
        collect_visible(node.children, depth + 1, result) if node.expanded
      end
    end

    sig { params(delta: Integer).void }
    def move_cursor(delta)
      max = visible_nodes.length - 1
      @cursor = (@cursor + delta).clamp(0, [max, 0].max)
    end

    sig { returns(T.nilable(TreeNode)) }
    def current_node
      visible_nodes[@cursor]&.first
    end

    sig { void }
    def toggle_current
      node = current_node
      return unless node&.expandable?

      node.expanded = !node.expanded
      refresh
    end

    sig { void }
    def expand_current
      node = current_node
      return unless node&.expandable?

      node.expanded = true
      refresh
    end

    sig { void }
    def collapse_current
      node = current_node
      return unless node&.expandable?

      node.expanded = false
      refresh
    end

    sig { void }
    def select_current
      node = current_node
      return unless node

      parent&.dispatch(NodeSelected.new(sender: self, node: node))
    end
  end
end
