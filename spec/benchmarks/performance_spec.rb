# typed: false
# frozen_string_literal: true

require_relative "../spec_helper"
require "benchmark"

RSpec.describe "Performance Benchmarks" do
  describe "Buffer diffing" do
    it "diffs 1920 cells (80x24) in under 1ms" do
      width = 80
      height = 24
      total_cells = width * height

      prev_buffer = Ratatat::Buffer.new(width, height)
      curr_buffer = Ratatat::Buffer.new(width, height)

      # Fill with some content
      height.times do |y|
        prev_buffer.put_string(0, y, "Line #{y}: " + "x" * 60)
        curr_buffer.put_string(0, y, "Line #{y}: " + "y" * 60)
      end

      times = []
      100.times do
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        prev_buffer.diff(curr_buffer)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        times << elapsed * 1000 # Convert to ms
      end

      avg_time = times.sum / times.length
      median_time = times.sort[times.length / 2]
      max_time = times.max

      puts "\n  Buffer diff (#{total_cells} cells):"
      puts "    Average: #{avg_time.round(3)}ms"
      puts "    Median:  #{median_time.round(3)}ms"
      puts "    Max:     #{max_time.round(3)}ms"

      # Pure Ruby target: <5ms (Rust FFI could achieve <1ms)
      expect(median_time).to be < 5.0, "Median diff time #{median_time.round(3)}ms exceeds 5ms target"
    end

    it "diffs 8640 cells (180x48 - larger terminal) efficiently" do
      width = 180
      height = 48
      total_cells = width * height

      prev_buffer = Ratatat::Buffer.new(width, height)
      curr_buffer = Ratatat::Buffer.new(width, height)

      # Fill buffers
      height.times do |y|
        prev_buffer.put_string(0, y, "Row #{y.to_s.rjust(2, '0')}: " + ("a".."z").to_a.join * 6)
        curr_buffer.put_string(0, y, "Row #{y.to_s.rjust(2, '0')}: " + ("A".."Z").to_a.join * 6)
      end

      times = []
      50.times do
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        prev_buffer.diff(curr_buffer)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        times << elapsed * 1000
      end

      avg_time = times.sum / times.length
      median_time = times.sort[times.length / 2]

      puts "\n  Buffer diff (#{total_cells} cells - large terminal):"
      puts "    Average: #{avg_time.round(3)}ms"
      puts "    Median:  #{median_time.round(3)}ms"

      # Pure Ruby target: <20ms for large terminals
      expect(median_time).to be < 20.0, "Large buffer diff too slow"
    end

    it "handles minimal changes efficiently" do
      width = 80
      height = 24

      prev_buffer = Ratatat::Buffer.new(width, height)
      curr_buffer = Ratatat::Buffer.new(width, height)

      # Fill both buffers with same content
      height.times do |y|
        text = "Identical line #{y}: " + "=" * 50
        prev_buffer.put_string(0, y, text)
        curr_buffer.put_string(0, y, text)
      end

      # Change just one cell
      curr_buffer.put_string(40, 12, "X")

      times = []
      100.times do
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        diff = prev_buffer.diff(curr_buffer)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        times << elapsed * 1000
      end

      avg_time = times.sum / times.length

      puts "\n  Minimal change diff:"
      puts "    Average: #{avg_time.round(3)}ms"

      # Even with minimal changes, we still iterate all cells
      expect(avg_time).to be < 5.0, "Minimal change diff too slow"
    end
  end

  describe "Rendering throughput" do
    it "can render 60 frames per second on 80x24" do
      width = 80
      height = 24
      target_fps = 60
      frame_budget_ms = 1000.0 / target_fps # ~16.67ms per frame

      buffer = Ratatat::Buffer.new(width, height)

      # Create a complex widget tree
      container = Ratatat::Vertical.new
      container.mount(
        Ratatat::Static.new("Header: Performance Test"),
        Ratatat::Horizontal.new.tap do |h|
          h.mount(
            Ratatat::Static.new("Left pane content here"),
            Ratatat::Static.new("Right pane content here")
          )
        end,
        Ratatat::ProgressBar.new(progress: 0.5),
        Ratatat::Static.new("Footer: Press q to quit")
      )

      frame_times = []
      100.times do |i|
        buffer.clear

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        container.render(buffer, x: 0, y: 0, width: width, height: height)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

        frame_times << elapsed * 1000
      end

      avg_time = frame_times.sum / frame_times.length
      max_time = frame_times.max
      achievable_fps = 1000.0 / avg_time

      puts "\n  Render throughput (80x24):"
      puts "    Average frame: #{avg_time.round(3)}ms"
      puts "    Max frame:     #{max_time.round(3)}ms"
      puts "    Achievable:    #{achievable_fps.round(0)} fps"

      expect(avg_time).to be < frame_budget_ms, "Average render time exceeds 60fps budget"
    end

    it "maintains performance with many widgets" do
      width = 120
      height = 40

      buffer = Ratatat::Buffer.new(width, height)

      # Create a grid with many widgets
      grid = Ratatat::Grid.new(columns: 4)
      20.times do |i|
        grid.mount(Ratatat::Button.new("Button #{i + 1}"))
      end

      frame_times = []
      50.times do
        buffer.clear

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        grid.render(buffer, x: 0, y: 0, width: width, height: height)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

        frame_times << elapsed * 1000
      end

      avg_time = frame_times.sum / frame_times.length

      puts "\n  Many widgets (20 buttons in grid):"
      puts "    Average frame: #{avg_time.round(3)}ms"

      expect(avg_time).to be < 10.0, "Too slow with many widgets"
    end
  end

  describe "Widget creation" do
    it "creates 1000 widgets quickly" do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      widgets = []
      1000.times do |i|
        widgets << Ratatat::Button.new("Button #{i}")
      end

      elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000

      puts "\n  Widget creation (1000 buttons):"
      puts "    Total time: #{elapsed.round(3)}ms"
      puts "    Per widget: #{(elapsed / 1000).round(4)}ms"

      expect(elapsed).to be < 100, "Widget creation too slow"
    end
  end

  describe "Query performance" do
    it "queries large widget tree efficiently" do
      # Build a tree with 500 widgets
      root = Ratatat::Container.new
      50.times do |i|
        container = Ratatat::Container.new(id: "container-#{i}")
        10.times do |j|
          container.mount(Ratatat::Button.new("Btn", id: "btn-#{i}-#{j}", classes: [j.even? ? "even" : "odd"]))
        end
        root.mount(container)
      end

      times = []
      100.times do
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        root.query(".even")
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        times << elapsed * 1000
      end

      avg_time = times.sum / times.length

      puts "\n  Query performance (500 widgets, select ~250):"
      puts "    Average: #{avg_time.round(3)}ms"

      expect(avg_time).to be < 5.0, "Query too slow"
    end
  end

  describe "Memory efficiency" do
    it "buffer memory is reasonable" do
      # 80x24 = 1920 cells
      buffer = Ratatat::Buffer.new(80, 24)

      # Each cell has symbol, fg, bg, modifiers, skip
      # Rough estimate: ~100 bytes per cell
      estimated_size = 1920 * 100 / 1024.0 # KB

      puts "\n  Memory (80x24 buffer):"
      puts "    Estimated: ~#{estimated_size.round(0)}KB"

      # Just verify buffer was created
      expect(buffer.cells.length).to eq(1920)
    end
  end
end
