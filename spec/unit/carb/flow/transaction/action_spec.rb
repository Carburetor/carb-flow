require "spec_helper"
require "carb/flow/transaction/action"
require "carb/rspec/service"
require "carb/monads"

describe Carb::Flow::Transaction::Action do
  include Carb::RSpec::Service

  before do
    @step       = ->(service:, args:, **step_args) { Carb::Monads.monadize(1) }
    @service    = -> {}
    @step_args  = { foo: :bar }
    @executable = Carb::Flow::Transaction::Action.new(
      @step,
      @service,
      @step_args
    )
  end

  it_behaves_like "Carb::Service" do
    before do
      @service      = @executable
      @success_call = -> { @service.() }
    end
  end

  it "can be initialized with 3 args" do
    Carb::Flow::Transaction::Action.new(:foo, :bar, [123])
  end

  it "has step" do
    expect(@executable.step).to eq @step
  end

  it "has service" do
    expect(@executable.service).to eq @service
  end

  it "has step_args" do
    expect(@executable.step_args).to eq @step_args
  end

  it "calls step with pass args" do
    allow(@step).to receive(:call).and_call_original

    @executable.(baz: 123)

    expect(@step).to have_received(:call)
      .with(service: @service, args: { baz: 123 }, **@step_args)
  end
end
