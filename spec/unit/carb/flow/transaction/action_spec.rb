require "spec_helper"
require "carb/flow/transaction/action"

describe Carb::Flow::Transaction::Action do
  before do
    @action = Carb::Flow::Transaction::Action.new(:foo, :bar, [123])
  end

  it "can be initialized with 3 args" do
    Carb::Flow::Transaction::Action.new(:foo, :bar, [123])
  end

  it "has step_name" do
    expect(@action.step_name).to eq :foo
  end

  it "has service_name" do
    expect(@action.service_name).to eq :bar
  end

  it "has args" do
    expect(@action.args).to eq [123]
  end
end
