require "spec_helper"
require "carb/rspec/service"
require "carb/flow/compose"
require "carb/monads"
require "carb/service/lambda"

describe Carb::Flow::Compose do
  include Carb::RSpec::Service

  before do
    @do_nothing      = ->(**args) { ::Carb::Monads.monadize(args) }
    @service_nothing = Carb::Service::Lambda.new(@do_nothing)
  end

  it_behaves_like "Carb::Service" do
    before do
      do_nothing    = @do_nothing
      @service      = Carb::Flow::Compose.new(do_nothing, do_nothing)
      @success_call = -> { @service.(foo: "foome") }
    end
  end

  it "defines steps using list of services and lambdas" do
    transaction = Carb::Flow::Compose.new(@do_nothing, @service_nothing)
    allow(@do_nothing).to receive(:call).and_call_original

    result = transaction.(foo: "foome")

    expect(result).to eq Carb::Monads.monadize({ foo: "foome" })
    expect(@do_nothing).to have_received(:call).twice
  end
end