require "spec_helper"
require "carb/service"
require "carb/steps/tee"
require "carb/monads"
require "carb/rspec/service"
require "carb/rspec/monads"

describe Carb::Steps::Tee do
  include Carb::RSpec::Service
  include Carb::RSpec::Monads

  before do
    @dummy_service = instance_spy(
      Carb::Service,
      call: Carb::Monads.monadize(123)
    )
  end

  it_behaves_like "Carb::Service" do
    before do
      @service      = Carb::Steps::Tee.new
      @success_call = -> { @service.(service: @dummy_service, args: {}) }
    end
  end

  it "runs #call on passed service" do
    step = Carb::Steps::Tee.new

    step.(service: @dummy_service, args: {})

    expect(@dummy_service).to have_received(:call)
  end

  it "runs #call on passed service with passed args" do
    step = Carb::Steps::Tee.new

    step.(service: @dummy_service, args: { foo: "bar" })

    expect(@dummy_service).to have_received(:call).with(foo: "bar")
  end

  it "runs #call on passed service and return args monad when successful" do
    args = { foo: "bar" }
    step = Carb::Steps::Tee.new

    monad = step.(service: @dummy_service, args: args)

    expect(monad).to be_a_success_monad
    expect(monad.value).to eq args
  end

  it "runs #call on passed service and return args monad when failure" do
    args = { foo: "bar" }
    step = Carb::Steps::Tee.new
    allow(@dummy_service).to receive(:call).and_return(Carb::Monads::Left(123))

    monad = step.(service: @dummy_service, args: args)

    expect(monad).to be_a_monad
    expect(monad).not_to be_a_success_monad
    expect(monad.value).to eq args
  end
end
