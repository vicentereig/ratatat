# typed: false
require_relative "spec_helper"

RSpec.describe Ratatat::Message do
  let(:sender) { double("widget") }

  describe "creation" do
    it "requires a sender" do
      msg = Ratatat::Message.new(sender: sender)
      expect(msg.sender).to eq(sender)
    end

    it "defaults bubble to true" do
      msg = Ratatat::Message.new(sender: sender)
      expect(msg.bubble).to eq(true)
    end

    it "records creation time" do
      before = Time.now
      msg = Ratatat::Message.new(sender: sender)
      after = Time.now
      expect(msg.time).to be_between(before, after)
    end
  end

  describe "#stop" do
    it "halts propagation" do
      msg = Ratatat::Message.new(sender: sender)
      expect(msg.stopped?).to eq(false)
      msg.stop
      expect(msg.stopped?).to eq(true)
    end
  end

  describe "#prevent_default" do
    it "suppresses default handler" do
      msg = Ratatat::Message.new(sender: sender)
      expect(msg.prevented?).to eq(false)
      msg.prevent_default
      expect(msg.prevented?).to eq(true)
    end
  end

  describe "bubble: false" do
    it "does not bubble" do
      msg = Ratatat::Message.new(sender: sender, bubble: false)
      expect(msg.bubble).to eq(false)
    end
  end
end

RSpec.describe Ratatat::Key do
  let(:sender) { double("widget") }

  describe "creation" do
    it "captures key and modifiers" do
      key = Ratatat::Key.new(sender: sender, key: :up, modifiers: Set[:ctrl])
      expect(key.key).to eq(:up)
      expect(key.modifiers).to eq(Set[:ctrl])
    end

    it "defaults modifiers to empty set" do
      key = Ratatat::Key.new(sender: sender, key: "a")
      expect(key.modifiers).to be_empty
    end
  end

  describe "modifier helpers" do
    it "detects ctrl" do
      key = Ratatat::Key.new(sender: sender, key: "c", modifiers: Set[:ctrl])
      expect(key.ctrl?).to eq(true)
      expect(key.alt?).to eq(false)
      expect(key.shift?).to eq(false)
    end

    it "detects alt" do
      key = Ratatat::Key.new(sender: sender, key: "x", modifiers: Set[:alt])
      expect(key.alt?).to eq(true)
    end

    it "detects shift" do
      key = Ratatat::Key.new(sender: sender, key: "A", modifiers: Set[:shift])
      expect(key.shift?).to eq(true)
    end
  end
end

RSpec.describe Ratatat::Resize do
  let(:sender) { double("widget") }

  it "captures width and height" do
    resize = Ratatat::Resize.new(sender: sender, width: 120, height: 40)
    expect(resize.width).to eq(120)
    expect(resize.height).to eq(40)
  end
end
