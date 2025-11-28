#!/usr/bin/env ruby
# frozen_string_literal: true

# Log Tailer Example
# A two-pane log viewer demonstrating the Ratatat framework
#
# Usage:
#   ruby examples/log_tailer.rb                    # Demo mode with sample data
#   ruby examples/log_tailer.rb /var/log/system.log  # Tail a file
#   tail -f /var/log/system.log | ruby examples/log_tailer.rb  # Pipe input
#
# Keys:
#   j/k, Up/Down - Navigate lines
#   g/G          - Go to first/last line
#   f            - Toggle follow mode
#   /            - Filter lines (type pattern, Enter to apply, Esc to cancel)
#   c            - Clear filter
#   q, Ctrl+C    - Quit

require_relative "../lib/ratatat"

# Custom widget for displaying log lines with selection
class LogList < Ratatat::Widget
  extend T::Sig

  CAN_FOCUS = true

  class LineSelected < Ratatat::Message
    extend T::Sig
    sig { returns(Integer) }
    attr_reader :index
    sig { returns(String) }
    attr_reader :line
    sig { params(sender: Ratatat::Widget, index: Integer, line: String).void }
    def initialize(sender:, index:, line:)
      super(sender: sender)
      @index = index
      @line = line
    end
  end

  sig { returns(T::Array[String]) }
  attr_reader :lines

  sig { returns(T.nilable(String)) }
  attr_reader :filter

  reactive :cursor, default: 0, repaint: true
  reactive :scroll_offset, default: 0, repaint: true

  sig { params(id: T.nilable(String), classes: T::Array[String]).void }
  def initialize(id: nil, classes: [])
    super(id: id, classes: classes)
    @lines = T.let([], T::Array[String])
    @all_lines = T.let([], T::Array[String])
    @filter = T.let(nil, T.nilable(String))
    @cursor = 0
    @scroll_offset = 0
    @view_height = T.let(10, Integer)
  end

  sig { params(line: String).void }
  def add_line(line)
    @all_lines << line
    apply_filter
    refresh
  end

  sig { params(pattern: T.nilable(String)).void }
  def set_filter(pattern)
    @filter = pattern.nil? || pattern.empty? ? nil : pattern
    apply_filter
    @cursor = [cursor, @lines.length - 1].min
    @cursor = 0 if @cursor.negative?
    refresh
  end

  sig { returns(T.nilable(String)) }
  def selected_line
    @lines[cursor]
  end

  sig { void }
  def go_to_end
    @cursor = [@lines.length - 1, 0].max
    ensure_visible
  end

  sig { params(message: Ratatat::Key).void }
  def on_key(message)
    case message.key
    when "up", "k"
      move_cursor(-1)
      message.stop
    when "down", "j"
      move_cursor(1)
      message.stop
    when "page_up"
      move_cursor(-@view_height)
      message.stop
    when "page_down"
      move_cursor(@view_height)
      message.stop
    when "g"
      @cursor = 0
      ensure_visible
      emit_selection
      message.stop
    when "G"
      go_to_end
      emit_selection
      message.stop
    end
  end

  sig { params(buffer: Ratatat::Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
  def render(buffer, x:, y:, width:, height:)
    @view_height = height

    visible_lines = @lines[@scroll_offset, height] || []
    visible_lines.each_with_index do |line, i|
      actual_index = @scroll_offset + i
      is_selected = actual_index == cursor

      # Highlight selected line
      if is_selected
        (0...width).each { |col| buffer.set(x + col, y + i, Ratatat::Cell.new(symbol: " ", bg: Ratatat::Color::Named::Blue)) }
        buffer.put_string(x, y + i, line[0, width] || "", bg: Ratatat::Color::Named::Blue, fg: Ratatat::Color::Named::White)
      else
        buffer.put_string(x, y + i, line[0, width] || "")
      end
    end
  end

  private

  sig { params(delta: Integer).void }
  def move_cursor(delta)
    return if @lines.empty?

    @cursor = (cursor + delta).clamp(0, @lines.length - 1)
    ensure_visible
    emit_selection
  end

  sig { void }
  def ensure_visible
    if cursor < @scroll_offset
      @scroll_offset = cursor
    elsif cursor >= @scroll_offset + @view_height
      @scroll_offset = cursor - @view_height + 1
    end
  end

  sig { void }
  def emit_selection
    line = selected_line
    parent&.dispatch(LineSelected.new(sender: self, index: cursor, line: line || ""))
  end

  sig { void }
  def apply_filter
    @lines = if @filter
               @all_lines.select { |l| l.include?(@filter) }
             else
               @all_lines.dup
             end
  end
end

# Detail pane showing selected line info
class DetailPane < Ratatat::Widget
  extend T::Sig

  reactive :content, default: "", repaint: true

  sig { params(id: T.nilable(String), classes: T::Array[String]).void }
  def initialize(id: nil, classes: [])
    super(id: id, classes: classes)
    @content = ""
  end

  sig { params(line: String, index: Integer).void }
  def show_line(line, index)
    @content = build_detail(line, index)
  end

  sig { params(buffer: Ratatat::Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
  def render(buffer, x:, y:, width:, height:)
    buffer.put_string(x, y, "─" * width)
    buffer.put_string(x, y, "┤ Details ├")

    lines = @content.split("\n")
    lines.each_with_index do |line, i|
      break if i + 1 >= height
      buffer.put_string(x, y + i + 1, line[0, width] || "")
    end
  end

  private

  sig { params(line: String, index: Integer).returns(String) }
  def build_detail(line, index)
    return "No line selected" if line.empty?

    parts = []
    parts << "Line ##{index + 1}"
    parts << "Length: #{line.length} chars"
    parts << ""

    # Try to parse as JSON
    if line.include?("{") && line.include?("}")
      begin
        require "json"
        json_match = line.match(/\{.*\}/m)
        if json_match
          parsed = JSON.parse(json_match[0])
          parts << "JSON detected:"
          parsed.each { |k, v| parts << "  #{k}: #{v}" }
        end
      rescue JSON::ParserError
        # Not valid JSON
      end
    end

    parts << ""
    parts << "Raw:"
    parts << line[0, 200]

    parts.join("\n")
  end
end

# Status bar
class StatusBar < Ratatat::Widget
  extend T::Sig

  reactive :total_lines, default: 0, repaint: true
  reactive :filtered_lines, default: 0, repaint: true
  reactive :cursor_pos, default: 0, repaint: true
  reactive :follow_mode, default: true, repaint: true
  reactive :filter_text, default: "", repaint: true
  reactive :mode, default: :normal, repaint: true

  sig { params(id: T.nilable(String), classes: T::Array[String]).void }
  def initialize(id: nil, classes: [])
    super(id: id, classes: classes)
    @total_lines = 0
    @filtered_lines = 0
    @cursor_pos = 0
    @follow_mode = true
    @filter_text = ""
    @mode = :normal
    @filter_input = T.let("", String)
  end

  sig { returns(String) }
  attr_accessor :filter_input

  sig { params(buffer: Ratatat::Buffer, x: Integer, y: Integer, width: Integer, height: Integer).void }
  def render(buffer, x:, y:, width:, height:)
    # Background
    (0...width).each { |col| buffer.set(x + col, y, Ratatat::Cell.new(symbol: " ", bg: Ratatat::Color::Named::Blue)) }

    text = case @mode
           when :filter
             "Filter: #{@filter_input}█  (Enter to apply, Esc to cancel)"
           else
             parts = []
             parts << "Lines: #{@cursor_pos + 1}/#{@filtered_lines}"
             parts << "(#{@total_lines} total)" if @filter_text && !@filter_text.empty?
             parts << "│ Follow: #{@follow_mode ? 'ON' : 'OFF'}"
             parts << "│ Filter: '#{@filter_text}'" if @filter_text && !@filter_text.empty?
             parts << "│ j/k:nav f:follow /:filter q:quit"
             parts.join(" ")
           end

    buffer.put_string(x, y, text[0, width] || "", bg: Ratatat::Color::Named::Blue, fg: Ratatat::Color::Named::White)
  end
end

# Main application
class LogTailer < Ratatat::App
  extend T::Sig

  BINDINGS = T.let([
    Ratatat::Binding.new("q", "quit", "Quit"),
    Ratatat::Binding.new("f", "toggle_follow", "Toggle follow"),
    Ratatat::Binding.new("/", "start_filter", "Filter"),
    Ratatat::Binding.new("c", "clear_filter", "Clear filter"),
  ], T::Array[Ratatat::Binding])

  sig { params(source: T.any(IO, StringIO)).void }
  def initialize(source:)
    super()
    @source = source
    @follow_mode = T.let(true, T::Boolean)
    @reader_thread = T.let(nil, T.nilable(Thread))
  end

  sig { override.returns(T::Array[Ratatat::Widget]) }
  def compose
    [
      Ratatat::Vertical.new(id: "main", ratios: [0.6, 0.39, 0.01]).tap do |v|
        v.mount(
          LogList.new(id: "log"),
          DetailPane.new(id: "detail"),
          StatusBar.new(id: "status")
        )
      end
    ]
  end

  sig { void }
  def on_mount
    # Start reader thread
    @reader_thread = Thread.new { read_input }

    # Update timer
    set_interval(0.1) { update_display }

    # Focus the log list
    query_one("#log")&.focus
  end

  sig { params(message: LogList::LineSelected).void }
  def on_loglist_lineselected(message)
    detail = T.cast(query_one("#detail"), T.nilable(DetailPane))
    detail&.show_line(message.line, message.index)

    status = T.cast(query_one("#status"), T.nilable(StatusBar))
    status&.cursor_pos = message.index if status
  end

  sig { void }
  def action_quit
    self.exit
  end

  sig { void }
  def action_toggle_follow
    @follow_mode = !@follow_mode
    status = T.cast(query_one("#status"), T.nilable(StatusBar))
    status&.follow_mode = @follow_mode if status
  end

  sig { void }
  def action_start_filter
    status = T.cast(query_one("#status"), T.nilable(StatusBar))
    return unless status

    status.mode = :filter
    status.filter_input = ""
  end

  sig { void }
  def action_clear_filter
    log_list = T.cast(query_one("#log"), T.nilable(LogList))
    log_list&.set_filter(nil)

    status = T.cast(query_one("#status"), T.nilable(StatusBar))
    status&.filter_text = "" if status
  end

  sig { params(message: Ratatat::Key).void }
  def on_key(message)
    status = T.cast(query_one("#status"), T.nilable(StatusBar))
    return unless status&.mode == :filter

    case message.key
    when "enter"
      apply_filter(status.filter_input)
      status.mode = :normal
      message.stop
    when "escape"
      status.mode = :normal
      message.stop
    when "backspace"
      status.filter_input = status.filter_input[0..-2] || ""
      message.stop
    else
      if message.key.length == 1
        status.filter_input += message.key
        message.stop
      end
    end
  end

  private

  sig { void }
  def read_input
    @source.each_line do |line|
      log_list = T.cast(query_one("#log"), T.nilable(LogList))
      log_list&.add_line(line.chomp)
    end
  rescue IOError
    # Stream closed
  end

  sig { void }
  def update_display
    log_list = T.cast(query_one("#log"), T.nilable(LogList))
    status = T.cast(query_one("#status"), T.nilable(StatusBar))
    return unless log_list && status

    # Follow mode
    if @follow_mode && !log_list.lines.empty?
      log_list.go_to_end
    end

    # Update status
    status.total_lines = log_list.instance_variable_get(:@all_lines).length
    status.filtered_lines = log_list.lines.length
    status.cursor_pos = log_list.cursor
  end

  sig { params(pattern: String).void }
  def apply_filter(pattern)
    log_list = T.cast(query_one("#log"), T.nilable(LogList))
    log_list&.set_filter(pattern)

    status = T.cast(query_one("#status"), T.nilable(StatusBar))
    status&.filter_text = pattern if status
  end
end

# Main entry point
if __FILE__ == $PROGRAM_NAME
  input_path = ARGV.shift

  source = if input_path && File.exist?(input_path)
             File.open(input_path, "r")
           elsif !$stdin.tty?
             $stdin
           else
             # Demo mode - generate sample log lines
             require "stringio"
             demo_lines = []
             demo_lines << "[2024-01-15 10:00:00] INFO: Application starting..."
             demo_lines << "[2024-01-15 10:00:01] DEBUG: Loading configuration"
             demo_lines << "[2024-01-15 10:00:02] INFO: Connected to database"
             demo_lines << '[2024-01-15 10:00:03] INFO: Request {"method":"GET","path":"/api/users","status":200}'
             demo_lines << "[2024-01-15 10:00:04] WARN: Slow query detected (2.3s)"
             demo_lines << '[2024-01-15 10:00:05] INFO: Request {"method":"POST","path":"/api/login","status":200}'
             demo_lines << "[2024-01-15 10:00:06] ERROR: Connection timeout to service X"
             demo_lines << "[2024-01-15 10:00:07] INFO: Retrying connection..."
             demo_lines << "[2024-01-15 10:00:08] INFO: Connection restored"
             demo_lines << '[2024-01-15 10:00:09] INFO: Request {"method":"GET","path":"/api/status","status":200}'
             demo_lines << "[2024-01-15 10:00:10] DEBUG: Cache hit ratio: 87%"
             demo_lines << "[2024-01-15 10:00:11] INFO: Background job completed"
             demo_lines << "[2024-01-15 10:00:12] INFO: Metrics exported"
             demo_lines << "[2024-01-15 10:00:13] WARN: High memory usage: 82%"
             demo_lines << "[2024-01-15 10:00:14] INFO: GC completed, freed 256MB"
             StringIO.new(demo_lines.join("\n") + "\n")
           end

  app = LogTailer.new(source: source)
  app.run
end
