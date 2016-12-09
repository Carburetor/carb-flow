require "spec_helper"
require "carb/flow"

describe Carb::Flow do
  it "has a version number" do
    expect(Carb::Flow::VERSION).to be_a String
  end
end
