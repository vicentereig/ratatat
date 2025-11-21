#!/usr/bin/env ruby

require_relative "../lib/ratatat"
require "thread"

# Minimal log tailer demo: left pane shows incoming lines, right pane shows the focused line.
class LogTailerView
  attr_accessor :cursor, :follow

  def initialize(buffer)
    @buffer = buffer
    @cursor = 1
    @follow = true
  end

  def move_cursor(delta)
    @cursor = [[@cursor + delta, 1].max, @buffer.length].min
    @follow = false
  end

  def toggle_follow
    @follow = !@follow
  end

  def render(rows:, cols:)
    footer_rows = 1
    body_rows = rows - footer_rows
    lines = @buffer.dup
    cursor_line = lines.fetch(@cursor - 1, "")

    detail_text = build_detail_text(cursor_line)

    split = Ratatat::Widgets::Split.new(
      left: Ratatat::Widgets::List.new(lines: lines, cursor: @cursor),
      right: Ratatat::Widgets::Detail.new(text: detail_text),
      ratio: 0.5
    )

    body = split.render(rows: body_rows, cols: cols)
    footer_text = "lines: #{lines.length}  cursor: #{@cursor}  follow: #{@follow ? 'on' : 'off'}  quit: q or Ctrl+C"
    footer = Ratatat::Widgets::Footer.new(footer_text).render(rows: footer_rows, cols: cols)
    body + footer
  end

  def build_detail_text(line)
    tokens = line.split(/\s+/)
    formatted = tokens.map { |t| "- #{t}" }
    header = ["Selected line #{@cursor}:", "tokens: #{tokens.length}"]
    (header + formatted).join("\n")
  end
end

buffer = []

# Read from file or STDIN; default to sample lines.
input_path = ARGV.shift
source =
  if input_path && File.exist?(input_path)
    File.open(input_path, "r")
  elsif !STDIN.tty?
    STDIN
  else
    # Built-in sample to keep the demo interactive without input.
    require "stringio"
    StringIO.new(["booting app", "connecting", "tailer ready"].join("\n"))
  end

reader = Thread.new do
  source.each_line do |line|
    buffer << line.chomp
    sleep 0.01
  end
end

view = LogTailerView.new(buffer)

driver =
  begin
    Ratatat::Driver::Ffi.new
  rescue StandardError
    warn "Using Null driver; build native shim with `cargo build -p ratatat-ffi --release` for TUI output."
    Ratatat::Driver::Null.new
  end

app = Ratatat::App.new(driver: driver, root: view, rows: 24, cols: 80)

Thread.new do
  loop do
    if view.follow && buffer.length > 0
      view.cursor = buffer.length
    end
    sleep 0.05
  end
end

app.run(interval: 0.05)

reader.join
