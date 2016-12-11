require "spec_helper"
require "carb/service"
require "carb/steps/try"
require "carb/monads"
require "carb/rspec/service"
require "carb/rspec/monads"

describe Carb::Steps::Try do
  include Carb::RSpec::Service
  include Carb::RSpec::Monads

  before do
    @service_monad = Carb::Monads.monadize(123)
    @dummy_service = instance_spy(Carb::Service, call: @service_monad)
  end

  it_behaves_like "Carb::Service" do
    before do
      @service      = Carb::Steps::Try.new
      @success_call = -> { @service.(service: @dummy_service, args: {}) }
    end
  end

  it "runs #call on passed service" do
    step = Carb::Steps::Try.new

    step.(service: @dummy_service, args: {})

    expect(@dummy_service).to have_received(:call)
  end

  it "runs #call on passed service with passed args" do
    step = Carb::Steps::Try.new

    step.(service: @dummy_service, args: { foo: "bar" })

    expect(@dummy_service).to have_received(:call).with(foo: "bar")
  end

  it "runs #call on passed service and return service monad when successful" do
    step = Carb::Steps::Try.new

    monad = step.(service: @dummy_service, args: { foo: "bar" })

    expect(monad).to be_a_success_monad
    expect(monad).to eq @service_monad
  end

  it "runs #call on passed service and return service monad when failure" do
    failure = Carb::Monads::Left(123)
    step    = Carb::Steps::Try.new
    allow(@dummy_service).to receive(:call).and_return(failure)

    monad = step.(service: @dummy_service, args: { foo: "bar" })

    expect(monad).to be_a_monad
    expect(monad).not_to be_a_success_monad
    expect(monad).to eq failure
  end

  it "runs #call on passed service and return Try::Failure when raises" do
    step = Carb::Steps::Try.new
    allow(@dummy_service).to receive(:call).and_raise(RuntimeError)

    monad = step.(service: @dummy_service, args: { foo: "bar" })

    expect(monad).to be_a_monad
    expect(monad).not_to be_a_success_monad
    expect(monad.exception).to be_a RuntimeError
  end

  it "runs #call and raises when specified exception not caught" do
    args = { foo: "bar" }
    step = Carb::Steps::Try.new
    allow(@dummy_service).to receive(:call).and_raise(RuntimeError)

    service_call = -> do
      step.(service: @dummy_service, args: args, exceptions: [TypeError])
    end

    expect{ service_call.() }.to raise_error RuntimeError
  end
end
