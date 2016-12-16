require "spec_helper"
require "carb/service"
require "carb/steps/step"
require "carb/monads"
require "carb/rspec/service"

describe Carb::Steps::Step do
  include Carb::RSpec::Service

  before do
    @dummy_service = instance_spy(
      Carb::Service,
      call: Carb::Monads.monadize(123)
    )
  end

  it_behaves_like "Carb::Service" do
    before do
      @service      = Carb::Steps::Step.new
      @success_call = -> { @service.(service: @dummy_service, args: {}) }
    end
  end

  it "runs #call on passed service" do
    step = Carb::Steps::Step.new

    step.(service: @dummy_service, args: {})

    expect(@dummy_service).to have_received(:call)
  end

  it "runs #call on passed service with passed args" do
    step = Carb::Steps::Step.new

    step.(service: @dummy_service, args: { foo: "bar" })

    expect(@dummy_service).to have_received(:call).with(foo: "bar")
  end
end
