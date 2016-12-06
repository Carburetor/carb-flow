# COMPOSE

Campaign::CreateWithContacts = Carb::Compose[
  Service1.new,
  Service2.new,
  Service3.new
]

composed = Campaign::CreateWithContacts.new
composed.("whatever")

# PIPE
Campaign::CreateWithContacts = Carb::Pipe(steps: steps) do
  step :create
  tee  :append_contacts
  step ->(campaign) { 123 }
end
# Creates a new class named `Campaign::CreateWithContacts`
# the class stores the block in an instance variable, and will invoke it with
# `call`
# Steps stored in `steps: ` are just used to replace the default, they can still
# be injected

pipe = Campaign::CreateWithContacts.new(steps: REPLACE_STEPS_DINAMICALLY)
pipe.("whatever")

# TRANSACTION
class Campaign::CreateWithContacts
  include Carb::Transaction
  include Inject[queue_step: "custom_step.queue"]

  # This initializer is an example of what is performed by Carb::Transaction.
  # It won't be in the main class
  def initialize(step_adapters: BASE_STEP_ADAPTERS)
    @step_adapters = step_adapters
    prepare
  end

  # Provide by Transaction, this actually won't be written and shouldn't be
  # touched
  def call(obj)
    wrapped = wrap_in_either(obj)

    steps.inject(wrapped) do |result, step|
      step.(result)
    end
  end

  # Class must provide this method
  # This is to allow dynamic steps, if you really need to. This version is
  # for "maximum expansion". Subscription to steps can be performed like
  # dry-transactions or step(:something).subscribe(obj)
  def prepare
    step  :something
    queue :something_else
    [1,2,3].each { |index| step :"foo_#{ index }" }
    tee   :something_else_again
  end

  protected

  # #step_adapters will be provided by Carb::Transaction and can be overloaded
  # This method is run on initialization and will create instance methods for
  # each key in the hashmap
  def step_adapters
    super.merge({
      queue: queue_step
    })
  end
end

transaction = Campaign::CreateWithContacts.new
transaction.("whatever")
