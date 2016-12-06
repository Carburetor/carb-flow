STEPS_STORED_SOMEWHERE = {
  tee:   container["steps.tee"],
  step:  container["steps.step"]
}.freeze

steps = STEPS_STORED_SOMEWHERE.merge({
  queue: container["carb.steps.queue"]
})

# By default steps = STEPS_STORED_SOMEWHERE
Campaign::CreateWithContacts = Carb::Pipe(steps: steps) do
  step :create
  tee  :append_contacts
  # Guideline should be that this lambda is at most one line long
  # Our lib will automatically wrap in an Either if not of that type (only
  # for lambdas).
  # Different step adapters might wrap the value differently:
  # a `try` might wrap result in a left if an error is catched
  step ->(campaign) {
    123
  }
end

# The input value gets automatically wrapped in a Result.Right
Campaign::CreateWithContacts.(Campaign.find(123))

# DISADVANTAGES
# - Can't subscribe to steps
# - Only a "global listener" for when steps are completed
# - Can't nest anything inside the constant unless we use a class
# - It's possible to subscribe to single steps, but you need to allocate the
#   listener before the `do end` block
listener = container["campaign.create_with_contacts.listener"]

Campaign::CreateWithContacts = Carb::Pipe(steps: steps) do
  step :create
  tee(:append_contacts).subscribe(:success, listener)
  step(->(campaign) { 123 }).subscribe(:success, listener)
end
