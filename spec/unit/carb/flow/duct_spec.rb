require "spec_helper"
require "carb/rspec/service"
require "carb/flow/duct"
require "carb/monads"

describe Carb::Flow::Duct do
  include Carb::RSpec::Service

  before do
    @do_nothing = ->(**args) { ::Carb::Monads.monadize(args) }
  end

  it_behaves_like "Carb::Service" do
    before do
      do_nothing = @do_nothing
      @service = Carb::Flow::Duct.new do
        step do_nothing
      end
      @success_call = -> { @service.(foo: "foome") }
    end
  end

  it "defines steps using passed block" do
    do_nothing  = @do_nothing
    pipeline = Carb::Flow::Duct.new do
      step do_nothing
    end

    result = pipeline.(foo: "foome")

    expect(result).to eq Carb::Monads.monadize({ foo: "foome" })
  end
end
