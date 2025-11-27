# typed: false
require_relative "spec_helper"

# A widget that tracks key messages
class KeyTracker < Ratatat::Widget
  CAN_FOCUS = true
  attr_reader :keys

  def initialize(**opts)
    super
    @keys = []
  end

  def on_key(message)
    @keys << message.key
    message.stop if message.key == :q
  end
end

RSpec.describe Ratatat::App do
  describe "message dispatch" do
    it "dispatches Key message to focused widget" do
      tracker = KeyTracker.new
      app = Ratatat::App.new
      app.mount(tracker)
      tracker.focus

      # Simulate a key press
      app.post(Ratatat::Key.new(sender: app, key: :up))
      app.process_messages

      expect(tracker.keys).to eq([:up])
    end

    it "stops on quit message" do
      app = Ratatat::App.new
      expect(app.running?).to eq(false)

      app.instance_variable_set(:@running, true)
      expect(app.running?).to eq(true)

      app.post(Ratatat::Quit.new(sender: app))
      app.process_messages

      expect(app.running?).to eq(false)
    end
  end

  describe "#exit" do
    it "posts a Quit message" do
      app = Ratatat::App.new
      app.instance_variable_set(:@running, true)

      app.exit
      app.process_messages

      expect(app.running?).to eq(false)
    end
  end

  describe "message bubbling" do
    it "bubbles from child to app" do
      received = []
      app_class = Class.new(Ratatat::App) do
        define_method(:on_key) do |msg|
          received << msg.key
        end
      end

      app = app_class.new
      child = Ratatat::Widget.new
      app.mount(child)

      # Dispatch from child
      child.dispatch(Ratatat::Key.new(sender: child, key: :down))

      expect(received).to eq([:down])
    end
  end
end
