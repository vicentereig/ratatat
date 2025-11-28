# typed: false
require_relative "../spec_helper"

RSpec.describe Ratatat::Sparkline do
  it "stores data points" do
    spark = Ratatat::Sparkline.new(data: [1, 2, 3, 4, 5])
    expect(spark.data).to eq([1, 2, 3, 4, 5])
  end

  it "renders using block characters" do
    spark = Ratatat::Sparkline.new(data: [0, 4, 8, 4, 0])
    buffer = Ratatat::Buffer.new(5, 1)
    spark.render(buffer, x: 0, y: 0, width: 5, height: 1)

    content = (0...5).map { |i| buffer[i, 0].symbol }.join
    # Should use block characters like ▁▃▇▃▁
    expect(content.length).to eq(5)
  end

  it "handles empty data" do
    spark = Ratatat::Sparkline.new(data: [])
    buffer = Ratatat::Buffer.new(5, 1)
    spark.render(buffer, x: 0, y: 0, width: 5, height: 1)
    # Should not crash
  end

  it "handles single value" do
    spark = Ratatat::Sparkline.new(data: [5])
    buffer = Ratatat::Buffer.new(5, 1)
    spark.render(buffer, x: 0, y: 0, width: 5, height: 1)

    content = (0...5).map { |i| buffer[i, 0].symbol }.join.strip
    expect(content.length).to eq(1)
  end

  it "scales to min/max" do
    spark = Ratatat::Sparkline.new(data: [10, 20, 30])
    buffer = Ratatat::Buffer.new(3, 1)
    spark.render(buffer, x: 0, y: 0, width: 3, height: 1)

    # First should be lowest block, last should be highest
    c0 = buffer[0, 0].symbol
    c2 = buffer[2, 0].symbol
    expect(c0).not_to eq(c2)
  end

  it "can add data points" do
    spark = Ratatat::Sparkline.new(data: [1, 2])
    spark.push(3)
    expect(spark.data).to eq([1, 2, 3])
  end

  it "respects max_data_points" do
    spark = Ratatat::Sparkline.new(data: [1, 2, 3], max_data_points: 3)
    spark.push(4)
    expect(spark.data).to eq([2, 3, 4])
  end
end
