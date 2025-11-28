# typed: false
require_relative "spec_helper"

RSpec.describe "Background Workers" do
  describe "#run_worker" do
    it "executes block in background" do
      app = Ratatat::App.new
      result = nil

      app.run_worker(:loader) do
        sleep 0.01
        "loaded data"
      end

      # Should not block
      sleep 0.05

      # Process pending worker completions
      app.process_workers

      # Check if done message was posted
      app.process_messages
    end

    it "posts Worker::Done message when complete" do
      done_result = nil
      done_name = nil

      # Create app that handles worker completion
      app_class = Class.new(Ratatat::App) do
        define_method(:on_worker_done) do |msg|
          done_name = msg.name
          done_result = msg.result
        end
      end

      app = app_class.new
      app.run_worker(:fetch) { "fetched!" }

      # Wait for worker to complete
      sleep 0.05
      app.process_workers
      app.process_messages

      expect(done_name).to eq(:fetch)
      expect(done_result).to eq("fetched!")
    end

    it "handles errors in workers" do
      error_received = nil

      app_class = Class.new(Ratatat::App) do
        define_method(:on_worker_done) do |msg|
          error_received = msg.error
        end
      end

      app = app_class.new
      app.run_worker(:fail) { raise "oops" }

      sleep 0.05
      app.process_workers
      app.process_messages

      expect(error_received).to be_a(RuntimeError)
      expect(error_received.message).to eq("oops")
    end

    it "can cancel a worker" do
      app = Ratatat::App.new
      completed = false

      widget_class = Class.new(Ratatat::Widget) do
        define_method(:on_worker_done) do |msg|
          completed = true
        end
      end

      widget = widget_class.new
      app.mount(widget)

      app.run_worker(:slow) { sleep 1 }
      app.cancel_worker(:slow)

      sleep 0.05
      app.process_workers
      app.process_messages

      expect(completed).to be false
    end
  end
end
