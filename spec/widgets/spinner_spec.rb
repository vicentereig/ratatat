# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Spinner do
  it "has default frames" do
    spinner = Ratatat::Spinner.new
    expect(spinner.frames).not_to be_empty
  end

  it "accepts custom frames" do
    spinner = Ratatat::Spinner.new(frames: ["-", "\\", "|", "/"])
    expect(spinner.frames).to eq(["-", "\\", "|", "/"])
  end

  it "has configurable speed" do
    spinner = Ratatat::Spinner.new(speed: 0.5)
    expect(spinner.speed).to eq(0.5)
  end

  it "cannot receive focus" do
    spinner = Ratatat::Spinner.new
    expect(spinner.can_focus?).to be false
  end

  it "starts at frame 0" do
    spinner = Ratatat::Spinner.new
    expect(spinner.frame_index).to eq(0)
  end

  it "advances to next frame" do
    spinner = Ratatat::Spinner.new(frames: ["a", "b", "c"])
    expect(spinner.current_frame).to eq("a")

    spinner.advance
    expect(spinner.current_frame).to eq("b")

    spinner.advance
    expect(spinner.current_frame).to eq("c")

    spinner.advance
    expect(spinner.current_frame).to eq("a") # wraps
  end

  it "renders current frame" do
    spinner = Ratatat::Spinner.new(frames: ["X", "Y"])
    buffer = Ratatat::Buffer.new(5, 1)
    spinner.render(buffer, x: 0, y: 0, width: 5, height: 1)

    row = (0...5).map { |i| buffer[i, 0].symbol }.join
    expect(row).to include("X")
  end

  it "can be started and stopped" do
    spinner = Ratatat::Spinner.new
    expect(spinner.spinning?).to be false

    spinner.start
    expect(spinner.spinning?).to be true

    spinner.stop
    expect(spinner.spinning?).to be false
  end

  it "supports predefined spinner styles" do
    dots = Ratatat::Spinner.new(style: :dots)
    expect(dots.frames).to eq(["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"])

    line = Ratatat::Spinner.new(style: :line)
    expect(line.frames).to eq(["-", "\\", "|", "/"])

    blocks = Ratatat::Spinner.new(style: :blocks)
    expect(blocks.frames).to eq(["▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"])
  end

  it "renders with optional text" do
    spinner = Ratatat::Spinner.new(text: "Loading...")
    buffer = Ratatat::Buffer.new(20, 1)
    spinner.render(buffer, x: 0, y: 0, width: 20, height: 1)

    row = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row).to include("Loading...")
  end
end
