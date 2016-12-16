require "spec_helper"
require "wisper/rspec/matchers"
require "carb/rspec/service"
require "carb/flow/transaction"

describe Carb::Flow::Transaction do
  include Carb::RSpec::Service
  include Wisper::RSpec::BroadcastMatcher

  before do
    @do_nothing = ->(**args) { Carb::Monads.monadize(true) }
    @do_fail    = ->(**args) { Carb::Monads.Left(false) }
    @say_foo = ->(foo:) do
      puts "foo #{ foo }"
      Carb::Monads.monadize({ bar: "baz" })
    end
    @say_bar = ->(bar:) do
      puts "bar #{ bar }"
      Carb::Monads.monadize({ blah: 123 })
    end
    @just_return = ->(**args) { Carb::Monads.monadize(args) }

    @transaction_class = Class.new(Carb::Flow::Transaction) do
      attr_reader :say_foo
      attr_reader :say_bar
      attr_reader :do_nothing
      attr_reader :do_fail
      attr_reader :just_return

      def initialize(say_foo:, say_bar:, do_nothing:, do_fail:, just_return:)
        super()
        @say_foo     = say_foo
        @say_bar     = say_bar
        @do_nothing  = do_nothing
        @do_fail     = do_fail
        @just_return = just_return
      end
    end

    @transaction = @transaction_class.new(
      say_foo:     @say_foo,
      say_bar:     @say_bar,
      do_nothing:  @do_nothing,
      do_fail:     @do_fail,
      just_return: @just_return
    )
  end

  it_behaves_like "Carb::Service" do
    before do
      @transaction.step :do_nothing
      @service = @transaction
      @success_call = -> { @transaction.() }
    end
  end

  it "raises if no steps provided" do
    expect{@transaction.()}.to raise_error Carb::Flow::Transaction::EmptyError
  end

  it "runs both steps" do
    @transaction.step :say_foo
    @transaction.step :say_bar
    allow(@say_foo).to receive(:call)
      .and_return(Carb::Monads.monadize({ bar: "barme" }))
    allow(@say_bar).to receive(:call)
      .and_return(Carb::Monads.monadize({ blah: 123 }))

    @transaction.(foo: "foome")

    expect(@say_foo).to have_received(:call).with(foo: "foome")
    expect(@say_bar).to have_received(:call).with(bar: "barme")
  end

  it "returns last step result" do
    @transaction.step :say_foo
    @transaction.step :say_bar
    result = nil

    expect{result = @transaction.(foo: "foome")}.to output.to_stdout
    expect(result).to eq Carb::Monads.monadize({ blah: 123 })
  end

  it "can use tee step" do
    allow(@do_nothing).to receive(:call).and_call_original
    @transaction.tee  :do_nothing
    @transaction.step :say_foo
    result = nil

    expect{result = @transaction.(foo: "foome")}.to output.to_stdout
    expect(@do_nothing).to have_received(:call)
    expect(result).to eq Carb::Monads.monadize({ bar: "baz" })
  end

  it "calls #setup" do
    allow(@transaction).to receive(:setup).and_call_original
    @transaction.step :do_nothing

    @transaction.()

    expect(@transaction).to have_received(:setup)
  end

  it "broadcasts start" do
    @transaction.step :do_nothing

    expect{@transaction.()}.to broadcast(:start, @transaction)
  end

  it "broadcasts success" do
    @transaction.step :do_nothing

    expect{@transaction.()}.to broadcast(:success, @transaction)
  end

  it "broadcasts failure" do
    @transaction.step :do_fail

    expect{@transaction.()}.to broadcast(:failure, @transaction)
  end

  it "broadcasts step_start" do
    @transaction.step :just_return

    expect{@transaction.(foo: 123)}.to broadcast(:step_start)
  end

  it "broadcasts step_success" do
    @transaction.step :just_return

    expect{@transaction.(foo: 123)}.to broadcast(:step_success)
  end

  it "broadcasts step_success" do
    @transaction.step :do_fail

    expect{@transaction.()}.to broadcast(:step_failure)
  end
end
