# typed: false
require_relative "spec_helper"

RSpec.describe "Async" do
  describe "#set_timer" do
    it "executes callback after delay" do
      app = Ratatat::App.new
      called = false

      app.set_timer(0.01) { called = true }

      expect(called).to be false
      sleep 0.02
      app.process_timers
      expect(called).to be true
    end

    it "returns a timer id" do
      app = Ratatat::App.new
      id = app.set_timer(1) { }
      expect(id).to be_a(Integer)
    end

    it "only fires once" do
      app = Ratatat::App.new
      count = 0

      app.set_timer(0.01) { count += 1 }

      sleep 0.02
      app.process_timers
      app.process_timers
      expect(count).to eq(1)
    end
  end

  describe "#set_interval" do
    it "executes callback repeatedly" do
      app = Ratatat::App.new
      count = 0

      app.set_interval(0.01) { count += 1 }

      sleep 0.015
      app.process_timers
      expect(count).to eq(1)

      sleep 0.015
      app.process_timers
      expect(count).to eq(2)
    end

    it "returns a timer id" do
      app = Ratatat::App.new
      id = app.set_interval(1) { }
      expect(id).to be_a(Integer)
    end
  end

  describe "#cancel_timer" do
    it "prevents timer from firing" do
      app = Ratatat::App.new
      called = false

      id = app.set_timer(0.01) { called = true }
      app.cancel_timer(id)

      sleep 0.02
      app.process_timers
      expect(called).to be false
    end

    it "stops interval from repeating" do
      app = Ratatat::App.new
      count = 0

      id = app.set_interval(0.01) { count += 1 }

      sleep 0.015
      app.process_timers
      expect(count).to eq(1)

      app.cancel_timer(id)
      sleep 0.02
      app.process_timers
      expect(count).to eq(1)
    end
  end

  describe "#call_later" do
    it "executes callback on next process_timers" do
      app = Ratatat::App.new
      called = false

      app.call_later { called = true }

      expect(called).to be false
      app.process_timers
      expect(called).to be true
    end

    it "executes in order" do
      app = Ratatat::App.new
      order = []

      app.call_later { order << 1 }
      app.call_later { order << 2 }
      app.call_later { order << 3 }

      app.process_timers
      expect(order).to eq([1, 2, 3])
    end

    it "only executes once" do
      app = Ratatat::App.new
      count = 0

      app.call_later { count += 1 }

      app.process_timers
      app.process_timers
      expect(count).to eq(1)
    end
  end

  describe "#call_after_refresh" do
    it "executes callback after render" do
      app = Ratatat::App.new
      called = false

      app.call_after_refresh { called = true }

      expect(called).to be false
      app.send(:process_post_refresh)
      expect(called).to be true
    end

    it "executes in order" do
      app = Ratatat::App.new
      order = []

      app.call_after_refresh { order << 1 }
      app.call_after_refresh { order << 2 }
      app.call_after_refresh { order << 3 }

      app.send(:process_post_refresh)
      expect(order).to eq([1, 2, 3])
    end

    it "only executes once" do
      app = Ratatat::App.new
      count = 0

      app.call_after_refresh { count += 1 }

      app.send(:process_post_refresh)
      app.send(:process_post_refresh)
      expect(count).to eq(1)
    end
  end
end
