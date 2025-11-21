require "spec_helper"

class DummyWidgetApp
  def render(rows:, cols:)
    Array.new(rows) { "x" * cols }
  end
end

RSpec.describe Ratatat::App do
  it "renders once via the driver" do
    driver = instance_double(Ratatat::Driver::Null)
    expect(driver).to receive(:open)
    expect(driver).to receive(:render) do |lines|
      expect(lines.first).to eq("xx")
    end
    expect(driver).to receive(:close)

    app = described_class.new(driver: driver, root: DummyWidgetApp.new, rows: 1, cols: 2)
    app.run_once
  end
end
