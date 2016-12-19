# carb-flow

Library which helps chaining service objects calls together. It requires
[carb-service](https://github.com/Carburetor/carb-service)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'carb-flow'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install carb-flow

## Usage

carb-flow comes with 3 services:

- Pipe
- Duct
- Pipeline

Pipeline is the most complex one, but probably you want to just use `Duct` or
`Pipe` instead.

These services helps you defining how to chain a series of service objects so
that the data _flows_ through them and gets mutated accordingly.

Every time the data passes from one service to another, it's considered a
_step_ of some kind. Currently there are 3 kind of steps available, and you can
supply your own custom ones:

- **Step** is the basic one: takes input argument, calls the service with
  supplied arguments and returns the result if successful, otherwise exits early
- **Tee** takes input arguments, calls the service with supplied arguments and
  returns **the input arguments**, wrapped inside a success monad. However if
  the service returns a failure monad, it returns that instead and exits early
- **Try** takes input arguments, call the service with supplied arguments and if
  raises or returns a failure monad, exits early without bubbling up the
  exception. By default, it catches `StandardError`, but an array of exceptions
  that should be catched can be supplied using the `exceptions` argument, which
  must be an array of error classes

You can provide your own custom steps (which are just service objects!) by
initializing `Pipe`, `Duct` or `Pipeline` with `steps` argument:

```ruby
mysteps = Carb::Steps::All.merge(
  queue: MyOwnQueueStep.new
)
duct = Carb::Flow::Duct.new(steps: mysteps) do
  step  :foo
  queue :bar
  # ...
end
```

In addition, notice that transaction has
[wisper](https://github.com/krisleech/wisper) support, which allows using the
observer pattern for logging or similar functionality.

### Pipe

This is the simplest service, allows you to create a chain of services in the
fastest way.

```ruby
require "carb/service"
require "carb/monads"
require "carb/pipe"

# Extracts name from a hash built like `{ contact: { name: "Foo" } }`
class ExtractName
  include Carb::Service

  def call(name_holder:)
    name = name_holder.fetch(:contact).fetch(:name).to_s
    Carb::Monads.Right(name: name)
  rescue KeyError => error
    Carb::Monads.Left(error: error)
  end
end

class CapitalizeName
  include Carb::Service

  def call(name:)
    Carb::Monads.Right(text: name.to_s.upcase)
  end
end

pipe = Carb::Flow::Pipe.new(
  ExtractName.new,
  CapitalizeName.new,
  ->(text:) { puts text.to_s }
)

pipe.(contact: { name: "Francesco" })

# prints "FRANCESCO"
```

### Duct

Duct is a service "half-way" between a full-fledged `Pipeline` and a simple
`Pipe`. Allows for much deeper customization of how steps are executed and
result returned:

```ruby
# Assume existing ExtractName and CapitalizeName from previous example

duct = Carb::Flow::Duct.new do
  try  ExtractName.new, exceptions: [KeyError]
  step CapitalizeName.new
  step ->(text:) {
    puts text.to_s
    { success: text }
  }
end

duct.(name: "Francesco") # Notice how we are passing the "wrong format"
# returns Carb::Monads::Try::Failure(exception: KeyError)

# If instead we pass the correct format
duct.(contact: { name: "Francesco" })

# prints "FRANCESCO" and returns
# Carb::Monads::Either::Right(success: "FRANCESCO")
```

### Pipeline

This is the most complex service. It has all the features of the other two, can
be inherited to extend functionality or create simpler utility classes like Pipe
and Duct.

The basic usage is meant to be inherit and overload the `setup` method:

```ruby
class MyPipeline < Carb::Flow::Pipeline
  def initialize(print_foo:, steps: ::Carb::Steps::All, actions: ActionList.new)
    super(steps: steps, actions: actions)
    @print_foo = print_foo
  end

  def setup(**args)
    step ->(value:) { ({ foo: value }) }
    # Notice how you can also use private methods returning services or lambdas
    step :print_foo
  end

  private

  def print_foo
    @print_foo
  end
end

pipeline = MyPipeline.new(print_foo: ->(foo:) { puts "foo #{ foo }" })
pipeline.(value: 123)

# prints "foo 123"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Carburetor/carb-flow.

