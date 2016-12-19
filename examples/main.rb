require "bundler/setup"
require "carb-core"
require "carb-inject"
require "carb-service"
require "carb-flow"

contacts = [
  ["Jon", "Snow", 17],
  ["Robb", "Stark", 17],
]

Contact   = Struct.new(:first_name, :last_name, :age, :clan)
Container = {}
Inject    = Carb::Inject::Injector.new(Container)

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

    Carb::Monads::Some([
      ["Jon", "Snow", 17],
      ["Robb", "Stark", 17],
    ])
  end
end

Container[:extract_from_csv] = ExtractFromCsv.new

class RowsToContacts
  include Carb::Service

  def call(*args)
    puts args.inspect
  end
end

Container[:rows_to_contacts] = RowsToContacts.new

pipe = Carb::Flow::Duct.new do
  step Container[:extract_from_csv]
  step Container[:rows_to_contacts]
end

pipe.(path: "foopath")
