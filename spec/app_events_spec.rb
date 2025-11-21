require "spec_helper"

class StubDriver
  attr_reader :frames

  def initialize(events:)
    @events = events.dup
    @frames = []
    @open = false
  end

  def open
    @open = true
  end

  def close
    @open = false
  end

  def render(lines)
    @frames << lines
  end

  def poll_event(_timeout_ms = 25)
    @events.shift
  end

  def size
    [3, 4]
  end
end

class CursorWidget
  attr_reader :cursor

  def initialize
    @cursor = 1
  end

  def move_cursor(delta)
    @cursor += delta
  end

  def render(rows:, cols:)
    ["c#{@cursor}".ljust(cols)] * rows
  end
end

RSpec.describe Ratatat::App do
  it "handles driver events and quits" do
    driver = StubDriver.new(events: [:down, :down, :quit])
    widget = CursorWidget.new

    app = described_class.new(driver: driver, root: widget)
    app.run(interval: 0.0)

    expect(widget.cursor).to eq(3) # two downs
    expect(driver.frames).not_to be_empty
  end
end
