require "bundler/setup"
require "carb-core"
require "carb-inject"
require "carb-service"
require "carb-flow"
require "pry-byebug"

contacts = [
  ["Jon", "Snow", 17],
  ["Robb", "Stark", 17],
]

Contact      = Struct.new(:first_name, :last_name, :age, :clan)
Container    = {}
# Provides automatically an initializer tht inject dependencies
Inject       = Carb::Inject::Injector.new(Container)
# Requires you to call `inject_dependencies!` inside the constructor, for
# increased flexibility
ManualInject = Carb::Inject::Injector.new(Container, auto_inject: false)

class PrintText
  include Carb::Service

  def call(text:)
    Carb::Monads::Try(IOError) { puts text.to_s }
  end
end

Container[:print_text] = PrintText.new

class ExtractFromCsv
  include Carb::Service
  include Inject[:print_text]

  def call(path:)
    # Pretend to read from file
    print_text.(text: "Reading from #{path}")

    Carb::Monads::Right(contacts: [
      ["Jon", "Snow", 17],
      ["Robb", "Stark", 17],
    ])
  end
end

Container[:extract_from_csv] = ExtractFromCsv.new

class RowsToContacts
  include Carb::Service

  def call(contacts:, clan:)
    Carb::Monads::Right(
      contacts: contacts.map { |contact| Contact.new(*contact, clan) }
    )
  end
end

Container[:rows_to_contacts] = RowsToContacts.new

# === USAGE ===

duct = Carb::Flow::Duct.new do
  step Container[:extract_from_csv]
  step Container[:rows_to_contacts].curry(clan: "Stark")
  tee  ->(contacts:) { puts contacts.inspect }
end

result = duct.(path: "foopath")

puts "result is #{ result.inspect }"

# Prints:
# Reading from foopath
# [#<struct Contact first_name="Jon", last_name="Snow", age=17, clan="Stark">, #<struct Contact first_name="Robb", last_name="Stark", age=17, clan="Stark">]
# result is Right({:contacts=>[#<struct Contact first_name="Jon", last_name="Snow", age=17, clan="Stark">, #<struct Contact first_name="Robb", last_name="Stark", age=17, clan="Stark">]})

# If instead of `tee` we use a simple step, the output is different!

duct = Carb::Flow::Duct.new do
  step Container[:extract_from_csv]
  step Container[:rows_to_contacts].curry(clan: "Stark")
  step ->(contacts:) { puts contacts.inspect }
end

result = duct.(path: "foopath")

puts "result is #{ result.inspect }"

# Reading from foopath
# [#<struct Contact first_name="Jon", last_name="Snow", age=17, clan="Stark">, #<struct Contact first_name="Robb", last_name="Stark", age=17, clan="Stark">]
# result is Right(nil)

# With a pipeline, syntax will look like the following:

class ExtractAndPrintContacts < Carb::Flow::Pipeline
  include ManualInject[:extract_from_csv, :rows_to_contacts]

  def initialize(**args)
    super
    inject_dependencies!(**args)
  end

  def setup(**args)
    step :extract_from_csv
    step rows_to_contacts.curry(clan: "Stark")
    tee  ->(contacts:) { puts contacts.inspect }
  end
end

pipeline = ExtractAndPrintContacts.new(lol: 123) # :lol key goes ignored
result   = pipeline.(path: "foopath")

puts "result is #{ result.inspect }"

# Reading from foopath
# [#<struct Contact first_name="Jon", last_name="Snow", age=17, clan="Stark">, #<struct Contact first_name="Robb", last_name="Stark", age=17, clan="Stark">]
# result is Right({:contacts=>[#<struct Contact first_name="Jon", last_name="Snow", age=17, clan="Stark">, #<struct Contact first_name="Robb", last_name="Stark", age=17, clan="Stark">]})

# Pipe uses `step` for everything, so the result is Right(nil)
pipe = Carb::Flow::Pipe.new(
  Container[:extract_from_csv],
  Container[:rows_to_contacts].curry(clan: "Stark"),
  ->(contacts:) { puts contacts.inspect }
)

result = pipe.(path: "foopath")

puts "result is #{ result.inspect }"

# Reading from foopath
# [#<struct Contact first_name="Jon", last_name="Snow", age=17, clan="Stark">, #<struct Contact first_name="Robb", last_name="Stark", age=17, clan="Stark">]
# result is Right(nil)

# Recommendations
# Use `initialize` only to inject external dependencies, to make testing
# easy. Don't use it for configuration
# Use `call` to configure the service itself. Use `curry` if you want to
# pre-supply some arguments for some services
# Keep every service with a single `call` method
# 4 kind of high level objects: Monads, Collections, Data and Services
