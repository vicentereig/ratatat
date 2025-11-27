# typed: strict
# frozen_string_literal: true

require "io/console"
require "sorbet-runtime"

module Ratatat
  # Terminal abstraction with double buffering for flicker-free rendering.
  # Manages two buffers (current and previous) and computes diffs.
  class Terminal
    extend T::Sig

    sig { returns(AnsiBackend) }
    attr_reader :backend

    sig { returns(Integer) }
    attr_reader :width, :height

    sig { params(backend: T.nilable(AnsiBackend), io: IO).void }
    def initialize(backend: nil, io: $stdout)
      @backend = T.let(backend || AnsiBackend.new(io: io), AnsiBackend)
      size = detect_size
      @width = T.let(size[0], Integer)
      @height = T.let(size[1], Integer)
      @buffers = T.let([Buffer.new(@width, @height), Buffer.new(@width, @height)], [Buffer, Buffer])
      @current = T.let(0, Integer)
      @cursor_hidden = T.let(false, T::Boolean)
    end

    # Get current buffer (the one being drawn to)
    sig { returns(Buffer) }
    def current_buffer
      @buffers[@current]
    end

    # Get previous buffer (last rendered frame)
    sig { returns(Buffer) }
    def previous_buffer
      @buffers[1 - @current]
    end

    # Draw a frame. Yields the current buffer for drawing.
    # After the block, computes diff and renders to terminal.
    sig { params(blk: T.proc.params(buffer: Buffer).void).void }
    def draw(&blk)
      # Check for resize
      check_resize

      # Clear current buffer
      current_buffer.clear

      # Let caller draw to buffer
      blk.call(current_buffer)

      # Compute diff and render
      flush
    end

    # Compute diff between buffers and render to terminal
    sig { void }
    def flush
      updates = previous_buffer.diff(current_buffer)
      @backend.draw(updates)
      @backend.flush
      swap_buffers
    end

    # Force a full redraw (no diffing)
    sig { void }
    def force_redraw
      @backend.clear
      previous_buffer.clear
      flush
    end

    # Swap current and previous buffers
    sig { void }
    def swap_buffers
      # Copy current to previous for next frame's diff
      previous_buffer.cells.each_with_index do |_, i|
        previous_buffer.cells[i] = T.must(current_buffer.cells[i])
      end
    end

    # Get current terminal size
    sig { returns([Integer, Integer]) }
    def size
      [@width, @height]
    end

    # Check if terminal was resized and update buffers
    sig { void }
    def check_resize
      new_width, new_height = detect_size
      return if new_width == @width && new_height == @height

      @width = new_width
      @height = new_height
      @buffers.each { |buf| buf.resize(@width, @height) }
    end

    # Enter raw mode and alternate screen
    sig { void }
    def enter
      @backend.enter_alternate_screen
      @backend.hide_cursor
      @backend.clear
      @cursor_hidden = true
      enable_raw_mode
    end

    # Exit raw mode and restore terminal
    sig { void }
    def exit
      @backend.show_cursor if @cursor_hidden
      @backend.reset_style
      @backend.leave_alternate_screen
      @backend.flush
      disable_raw_mode
      @cursor_hidden = false
    end

    # Show cursor at position
    sig { params(x: T.nilable(Integer), y: T.nilable(Integer)).void }
    def show_cursor(x = nil, y = nil)
      if x && y
        @backend.io.write(@backend.move_to(x, y))
      end
      @backend.show_cursor
      @cursor_hidden = false
    end

    # Hide cursor
    sig { void }
    def hide_cursor
      @backend.hide_cursor
      @cursor_hidden = true
    end

    private

    sig { returns([Integer, Integer]) }
    def detect_size
      if $stdout.respond_to?(:winsize)
        rows, cols = $stdout.winsize
        [cols || 80, rows || 24]
      else
        [80, 24]
      end
    rescue StandardError
      [80, 24]
    end

    sig { void }
    def enable_raw_mode
      $stdin.raw! if $stdin.respond_to?(:raw!)
    rescue StandardError
      # Ignore if we can't enter raw mode
    end

    sig { void }
    def disable_raw_mode
      $stdin.cooked! if $stdin.respond_to?(:cooked!)
    rescue StandardError
      # Ignore if we can't restore mode
    end
  end
end
