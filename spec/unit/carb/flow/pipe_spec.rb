require "spec_helper"
require "carb/rspec/service"
require "carb/flow/pipe"

describe Carb::Flow::Pipe do
  include Carb::RSpec::Service

  before do
    @say_foo = ->(foo:) do
      puts "foo #{ foo }"
      Carb::Monads.monadize({ bar: "baz" })
    end
    @say_bar = ->(bar:) do
      puts "bar #{ bar }"
      Carb::Monads.monadize({ blah: 123 })
    end

    say_foo = @say_foo
    say_bar = @say_bar
    lol = "asd"

    @transaction = Carb::Flow::Pipe.new do
      puts lol
      step say_foo
    end
  end

  it_behaves_like "Carb::Service" do
    before do
      @service = @transaction
      @success_call = -> { @transaction.(foo: "foome") }
    end
  end

  it "defines steps" do
    result = nil

    expect{result = @transaction.(foo: "foome")}.to output.to_stdout
    expect(result.value).to eq({ blah: 123 })
  end
end
