# COMPOSE

Campaign::CreateWithContacts = Carb::Pipe[
  Service1.new,
  Service2.new,
  Service3.new
]

piped = Campaign::CreateWithContacts.new
piped.("whatever")

# PIPE
Campaign::CreateWithContacts = Carb::Duct(steps: steps) do
  step :create
  tee  :append_contacts
  step ->(campaign) { 123 }
end
# Creates a new class named `Campaign::CreateWithContacts`
# the class stores the block in an instance variable, and will invoke it with
# `call`
# Steps stored in `steps: ` are just used to replace the default, they can still
# be injected

duct = Campaign::CreateWithContacts.new(steps: REPLACE_STEPS_DINAMICALLY)
duct.("whatever")

# TRANSACTION
class Campaign::CreateWithContacts
  include Carb::Pipeline
  include Inject[queue_step: "custom_step.queue"]

  # This initializer is an example of what is performed by Carb::Pipeline.
  # It won't be in the main class
  def initialize(step_adapters: BASE_STEP_ADAPTERS)
    @step_adapters = step_adapters
    prepare
  end

  # Provide by Pipeline, this actually won't be written and shouldn't be
  # touched
  def call(obj)
    # Any monad is fine, even a maybe, they all respond to `bind`
    wrapped = wrap_in_right_if_not_inside_monad(obj)

    steps.inject(wrapped) do |result, step|
      result.bind { |value| step.(value) }
    end
  end

  # Class must provide this method
  # This is to allow dynamic steps, if you really need to. This version is
  # for "maximum expansion". Subscription to steps can be performed like
  # dry-pipelines or step(:something).subscribe(obj)
  def prepare
    step  :something
    queue :something_else
    [1,2,3].each { |index| step :"foo_#{ index }" }
    tee   :something_else_again
  end

  protected

  # #step_adapters will be provided by Carb::Pipeline and can be overloaded
  # This method is run on initialization and will create instance methods for
  # each key in the hashmap
  def step_adapters
    super.merge({
      queue: queue_step
    })
  end
end

pipeline = Campaign::CreateWithContacts.new
pipeline.("whatever")

# SERVICE

# We need a method that takes an object and returns a Right(value) or the object
# itself if it's a monad (of any kind)

module Carb::Service
  # Must return an Left or Right
  def call(**args)
    raise NotImplementedError
  end
end


# We will provide a test helper that will check we adhere to the interface
# It will check the following things:
# - #call must return a Monad
# - #call must accept a single argument (a hashmap is a valid argument)
# - This shared examples must work with any lambda returning a monad
it_behaves_like "Carb::Service"

# - The object MUST have a single public method (#call) (check public_methods - Proc.instance_methods), maybe this is too restrictive?
# - The object must support `subscribe` (from Wisper)
it_behaves_like "Carb::Service::Strict"

# Eventually we can provide a Carb:Service::Lambda which takes a lambda, store
# it inside and provides "subscribe"
