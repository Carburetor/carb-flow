require "spec_helper"
require "wisper/rspec/matchers"
require "carb/rspec/service"
require "carb/service/lambda"
require "carb/flow/pipeline"

describe Carb::Flow::Pipeline do
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

    @pipeline_class = Class.new(Carb::Flow::Pipeline) do
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

    @pipeline = @pipeline_class.new(
      say_foo:     @say_foo,
      say_bar:     @say_bar,
      do_nothing:  @do_nothing,
      do_fail:     @do_fail,
      just_return: @just_return
    )
  end

  it_behaves_like "Carb::Service" do
    before do
      @pipeline.step :do_nothing
      @service = @pipeline
      @success_call = -> { @pipeline.() }
    end
  end

  it "raises if no steps provided" do
    expect{@pipeline.()}.to raise_error Carb::Flow::Pipeline::EmptyError
  end

  it "runs both steps" do
    @pipeline.step :say_foo
    @pipeline.step :say_bar
    allow(@say_foo).to receive(:call)
      .and_return(Carb::Monads.monadize({ bar: "barme" }))
    allow(@say_bar).to receive(:call)
      .and_return(Carb::Monads.monadize({ blah: 123 }))

    @pipeline.(foo: "foome")

    expect(@say_foo).to have_received(:call).with(foo: "foome")
    expect(@say_bar).to have_received(:call).with(bar: "barme")
  end

  it "returns last step result" do
    @pipeline.step :say_foo
    @pipeline.step :say_bar
    result = nil

    expect{result = @pipeline.(foo: "foome")}.to output.to_stdout
    expect(result).to eq Carb::Monads.monadize({ blah: 123 })
  end

  it "can use tee step" do
    allow(@do_nothing).to receive(:call).and_call_original
    @pipeline.tee  :do_nothing
    @pipeline.step :say_foo
    result = nil

    expect{result = @pipeline.(foo: "foome")}.to output.to_stdout
    expect(@do_nothing).to have_received(:call)
    expect(result).to eq Carb::Monads.monadize({ bar: "baz" })
  end

  it "can use lambda as service" do
    @pipeline.step ->(**args) { puts "hello" }
    result = nil

    expect{result = @pipeline.()}.to output(/hello/).to_stdout
    expect(result).to eq Carb::Monads.monadize(nil)
  end

  it "can use service as argument for step" do
    service = ::Carb::Service::Lambda.new(->(**args) { args })
    @pipeline.step service

    result = @pipeline.(foo: "bar")

    expect(result).to eq Carb::Monads.monadize(foo: "bar")
  end

  it "calls #setup" do
    allow(@pipeline).to receive(:setup).and_call_original
    @pipeline.step :do_nothing

    @pipeline.()

    expect(@pipeline).to have_received(:setup)
  end

  it "broadcasts start" do
    @pipeline.step :do_nothing

    expect{@pipeline.()}.to broadcast(:start, @pipeline)
  end

  it "broadcasts success" do
    @pipeline.step :do_nothing

    expect{@pipeline.()}.to broadcast(:success, @pipeline)
  end

  it "broadcasts failure" do
    @pipeline.step :do_fail

    expect{@pipeline.()}.to broadcast(:failure, @pipeline)
  end

  it "broadcasts step_start" do
    @pipeline.step :just_return

    expect{@pipeline.(foo: 123)}.to broadcast(:step_start)
  end

  it "broadcasts step_success" do
    @pipeline.step :just_return

    expect{@pipeline.(foo: 123)}.to broadcast(:step_success)
  end

  it "broadcasts step_success" do
    @pipeline.step :do_fail

    expect{@pipeline.()}.to broadcast(:step_failure)
  end
end
