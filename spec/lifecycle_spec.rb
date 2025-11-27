# typed: false
require_relative "spec_helper"

class LifecycleTracker < Ratatat::Widget
  CAN_FOCUS = true

  attr_reader :events

  def initialize(**opts)
    super
    @events = []
  end

  def on_mount
    @events << :mount
  end

  def on_unmount
    @events << :unmount
  end

  def on_focus(_msg)
    @events << :focus
  end

  def on_blur(_msg)
    @events << :blur
  end
end

RSpec.describe "Lifecycle Hooks" do
  describe "on_mount" do
    it "is called when widget is mounted" do
      app = Ratatat::App.new
      tracker = LifecycleTracker.new

      app.mount(tracker)

      expect(tracker.events).to eq([:mount])
    end

    it "is called for nested mounts" do
      app = Ratatat::App.new
      parent = LifecycleTracker.new(id: "parent")
      child = LifecycleTracker.new(id: "child")

      parent.mount(child)
      app.mount(parent)

      expect(parent.events).to eq([:mount])
      expect(child.events).to eq([:mount])
    end
  end

  describe "on_unmount" do
    it "is called when widget is removed" do
      app = Ratatat::App.new
      tracker = LifecycleTracker.new

      app.mount(tracker)
      tracker.events.clear

      tracker.remove

      expect(tracker.events).to eq([:unmount])
    end
  end

  describe "Focus messages" do
    it "dispatches Focus message when gaining focus" do
      app = Ratatat::App.new
      tracker = LifecycleTracker.new
      app.mount(tracker)
      tracker.events.clear

      tracker.focus

      expect(tracker.events).to eq([:focus])
    end

    it "dispatches Blur message when losing focus" do
      app = Ratatat::App.new
      t1 = LifecycleTracker.new(id: "t1")
      t2 = LifecycleTracker.new(id: "t2")
      app.mount(t1, t2)

      t1.focus
      t1.events.clear
      t2.events.clear

      t2.focus

      expect(t1.events).to eq([:blur])
      expect(t2.events).to eq([:focus])
    end
  end
end
