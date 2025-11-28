# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::ProgressBar do
  it "stores progress value" do
    bar = Ratatat::ProgressBar.new(progress: 0.5)
    expect(bar.progress).to eq(0.5)
  end

  it "defaults to 0" do
    bar = Ratatat::ProgressBar.new
    expect(bar.progress).to eq(0.0)
  end

  it "clamps progress to 0-1" do
    bar = Ratatat::ProgressBar.new
    bar.progress = 1.5
    expect(bar.progress).to eq(1.0)

    bar.progress = -0.5
    expect(bar.progress).to eq(0.0)
  end

  it "renders progress bar" do
    bar = Ratatat::ProgressBar.new(progress: 0.5)
    buffer = Ratatat::Buffer.new(10, 1)
    bar.render(buffer, x: 0, y: 0, width: 10, height: 1)

    # 50% of 10 = 5 filled
    content = (0...10).map { |i| buffer[i, 0].symbol }.join
    filled = content.count("█")
    expect(filled).to eq(5)
  end

  it "renders 0% progress" do
    bar = Ratatat::ProgressBar.new(progress: 0.0)
    buffer = Ratatat::Buffer.new(10, 1)
    bar.render(buffer, x: 0, y: 0, width: 10, height: 1)

    content = (0...10).map { |i| buffer[i, 0].symbol }.join
    expect(content.count("█")).to eq(0)
  end

  it "renders 100% progress" do
    bar = Ratatat::ProgressBar.new(progress: 1.0)
    buffer = Ratatat::Buffer.new(10, 1)
    bar.render(buffer, x: 0, y: 0, width: 10, height: 1)

    content = (0...10).map { |i| buffer[i, 0].symbol }.join
    expect(content.count("█")).to eq(10)
  end

  it "has total and completed" do
    bar = Ratatat::ProgressBar.new(total: 100.0, completed: 25.0)
    expect(bar.progress).to eq(0.25)
  end

  it "advances completed" do
    bar = Ratatat::ProgressBar.new(total: 100.0)
    bar.advance(10.0)
    expect(bar.completed).to eq(10.0)
    expect(bar.progress).to eq(0.1)

    bar.advance(15.0)
    expect(bar.completed).to eq(25.0)
  end
end

RSpec.describe Ratatat::Spinner do
  it "cycles through frames" do
    spinner = Ratatat::Spinner.new
    frames = []
    4.times { frames << spinner.current_frame; spinner.advance }
    expect(frames.uniq.length).to be > 1
  end

  it "renders current frame" do
    spinner = Ratatat::Spinner.new
    buffer = Ratatat::Buffer.new(5, 1)
    spinner.render(buffer, x: 0, y: 0, width: 5, height: 1)

    content = (0...5).map { |i| buffer[i, 0].symbol }.join.strip
    expect(content.length).to be >= 1
  end
end
