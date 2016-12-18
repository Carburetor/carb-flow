class Campaign::CreateWithContacts
  include Carb::Duct
  include Inject[
    "step.delayed_job", "step.tee",
    create:          "campaign.create",
    append_contacts: "campaign.append_contacts"
  ]

  protected

  def steps
    step :create
    tee  :append_contacts
    step ->(campaign) { contacts_as_json(campaign) }
  end

  # Step alternatives
  def steps
             step   :create
             tee    :append_contacts
    internal :step, :contacts_as_json
  end
  # End

  def adapters
    super.merge({
      queue: step_delayed_job,
      tee:   step_tee
    })
  end

  private

  def contacts_as_json(campaign)
    campaign.contacts.as_json
  end
end

create = Campaign::CreateWithContacts.new
create.(campaign)
