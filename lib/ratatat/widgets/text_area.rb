# typed: strict
# frozen_string_literal: true

module Ratatat
  # Multi-line text input widget
  class TextArea < Widget
    extend T::Sig

    CAN_FOCUS = true

    class Changed < Message
      extend T::Sig

      sig { returns(String) }
      attr_reader :value

      sig { params(sender: Widget, value: String).void }
      def initialize(sender:, value:)
        super(sender: sender)
        @value = value
      end
    end

    reactive :value, default: "", repaint: true

    sig { returns(Integer) }
    attr_reader :cursor_row, :cursor_col

    sig { params(value: String, id: T.nilable(String), classes: T::Array[String]).void }
    def initialize(value: "", id: nil, classes: [])
      super(id: id, classes: classes)
      @value = value
      @cursor_row = T.let(0, Integer)
      @cursor_col = T.let(value.split("\n").first&.length || 0, Integer)
    end

    sig { returns(T::Array[String]) }
    def lines
      @value.split("\n", -1)
    end

    sig { params(message: Key).void }
    def on_key(message)
      case message.key
      when "up"
        move_cursor_vertical(-1)
        message.stop
      when "down"
        move_cursor_vertical(1)
        message.stop
      when "left"
        move_cursor_horizontal(-1)
        message.stop
      when "right"
        move_cursor_horizontal(1)
        message.stop
      when "home"
        @cursor_col = 0
        message.stop
      when "end"
        @cursor_col = current_line.length
        message.stop
      when "enter"
        insert_newline
        message.stop
      when "backspace"
        delete_backward
        message.stop
      when "delete"
        delete_forward
        message.stop
      else
        insert_char(message.key) if message.key.length == 1
        message.stop
      end
    end

    sig { params(buffer: Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
    def render(buffer, x:, y:, width:, height:)
      lines.each_with_index do |line, i|
        break if i >= height

        buffer.put_string(x, y + i, line[0, width] || "")
      end
    end

    private

    sig { returns(String) }
    def current_line
      lines[@cursor_row] || ""
    end

    sig { params(delta: Integer).void }
    def move_cursor_vertical(delta)
      new_row = (@cursor_row + delta).clamp(0, [lines.length - 1, 0].max)
      @cursor_row = new_row
      @cursor_col = [@cursor_col, current_line.length].min
    end

    sig { params(delta: Integer).void }
    def move_cursor_horizontal(delta)
      @cursor_col = (@cursor_col + delta).clamp(0, current_line.length)
    end

    sig { params(char: String).void }
    def insert_char(char)
      current_lines = lines
      line = current_lines[@cursor_row] || ""
      new_line = line.dup
      new_line.insert(@cursor_col, char)
      current_lines[@cursor_row] = new_line
      @cursor_col += 1
      self.value = current_lines.join("\n")
      emit_changed
    end

    sig { void }
    def insert_newline
      current_lines = lines
      line = current_lines[@cursor_row] || ""
      before = line[0, @cursor_col] || ""
      after = line[@cursor_col..] || ""
      current_lines[@cursor_row] = before
      current_lines.insert(@cursor_row + 1, after)
      @cursor_row += 1
      @cursor_col = 0
      self.value = current_lines.join("\n")
      emit_changed
    end

    sig { void }
    def delete_backward
      if @cursor_col > 0
        current_lines = lines
        line = current_lines[@cursor_row] || ""
        new_line = line.dup
        new_line.slice!(@cursor_col - 1)
        current_lines[@cursor_row] = new_line
        @cursor_col -= 1
        self.value = current_lines.join("\n")
        emit_changed
      elsif @cursor_row > 0
        # Merge with previous line
        current_lines = lines
        prev_line = current_lines[@cursor_row - 1] || ""
        curr_line = current_lines[@cursor_row] || ""
        @cursor_col = prev_line.length
        current_lines[@cursor_row - 1] = prev_line + curr_line
        current_lines.delete_at(@cursor_row)
        @cursor_row -= 1
        self.value = current_lines.join("\n")
        emit_changed
      end
    end

    sig { void }
    def delete_forward
      current_lines = lines
      line = current_lines[@cursor_row] || ""

      if @cursor_col < line.length
        new_line = line.dup
        new_line.slice!(@cursor_col)
        current_lines[@cursor_row] = new_line
        self.value = current_lines.join("\n")
        emit_changed
      elsif @cursor_row < current_lines.length - 1
        # Merge with next line
        next_line = current_lines[@cursor_row + 1] || ""
        current_lines[@cursor_row] = line + next_line
        current_lines.delete_at(@cursor_row + 1)
        self.value = current_lines.join("\n")
        emit_changed
      end
    end

    sig { void }
    def emit_changed
      parent&.dispatch(Changed.new(sender: self, value: @value))
    end
  end
end
