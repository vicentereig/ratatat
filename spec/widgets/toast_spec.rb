# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Toast do
  it "stores message and severity" do
    toast = Ratatat::Toast.new(message: "Success!", severity: :success)
    expect(toast.message).to eq("Success!")
    expect(toast.severity).to eq(:success)
  end

  it "has default severity of info" do
    toast = Ratatat::Toast.new(message: "Hello")
    expect(toast.severity).to eq(:info)
  end

  it "has configurable duration" do
    toast = Ratatat::Toast.new(message: "Quick", duration: 2.0)
    expect(toast.duration).to eq(2.0)
  end

  it "cannot receive focus" do
    toast = Ratatat::Toast.new(message: "Test")
    expect(toast.can_focus?).to be false
  end

  it "renders with icon based on severity" do
    toast_info = Ratatat::Toast.new(message: "Info")
    toast_success = Ratatat::Toast.new(message: "OK", severity: :success)
    toast_warning = Ratatat::Toast.new(message: "Warn", severity: :warning)
    toast_error = Ratatat::Toast.new(message: "Err", severity: :error)

    buffer = Ratatat::Buffer.new(20, 1)

    toast_info.render(buffer, x: 0, y: 0, width: 20, height: 1)
    row = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row).to include("ℹ")

    buffer = Ratatat::Buffer.new(20, 1)
    toast_success.render(buffer, x: 0, y: 0, width: 20, height: 1)
    row = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row).to include("✓")

    buffer = Ratatat::Buffer.new(20, 1)
    toast_warning.render(buffer, x: 0, y: 0, width: 20, height: 1)
    row = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row).to include("⚠")

    buffer = Ratatat::Buffer.new(20, 1)
    toast_error.render(buffer, x: 0, y: 0, width: 20, height: 1)
    row = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row).to include("✗")
  end

  it "renders message text" do
    toast = Ratatat::Toast.new(message: "Hello World")
    buffer = Ratatat::Buffer.new(20, 1)
    toast.render(buffer, x: 0, y: 0, width: 20, height: 1)

    row = (0...20).map { |i| buffer[i, 0].symbol }.join
    expect(row).to include("Hello World")
  end

  it "tracks visibility state" do
    toast = Ratatat::Toast.new(message: "Test")
    expect(toast.visible).to be true

    toast.hide
    expect(toast.visible).to be false

    toast.show
    expect(toast.visible).to be true
  end
end
