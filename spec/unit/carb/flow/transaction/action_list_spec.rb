require "spec_helper"
require "carb/flow/transaction/action"
require "carb/flow/transaction/action_list"

describe Carb::Flow::Transaction::ActionList do
  before do
    @action      = Carb::Flow::Transaction::Action.new(:foo, :bar, [123])
    @action_list = Carb::Flow::Transaction::ActionList.new
  end

  it "can be initialized with another list" do
    @action_list << @action

    other = Carb::Flow::Transaction::ActionList.new(@action_list)

    expect(@action_list.to_a).to eq [@action]
  end

  it "has support for adding actions" do
    @action_list << @action
  end

  it "can't add non-action objects" do
    expect{@action_list << 123}.to raise_error TypeError
  end

  it "can be converted to array" do
    @action_list << @action

    expect(@action_list.to_a).to eq [@action]
  end

  it "is empty when no action added" do
    expect(@action_list).to be_empty
  end

  it "is not empty when action added" do
    @action_list << @action

    expect(@action_list).not_to be_empty
  end

  it "loops over each action" do
    looped_times = 0
    @action_list << @action

    @action_list.each { |_, _| looped_times += 1 }

    expect(looped_times).to eq 1
  end

  it "yields is_last true only on last action" do
    action2      = Carb::Flow::Transaction::Action.new(:baz, :blah, [456])
    looped_times = 0
    @action_list << action2
    @action_list << @action

    @action_list.each do |action, is_last|
      looped_times += 1
      expect(is_last).to be true   if looped_times == 2
      expect(action).to eq @action if is_last
    end

    expect(looped_times).to eq 2
  end
end
