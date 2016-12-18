require "carb"
require "carb/flow/pipe"

module Carb::Flow
  # Allows very easy and straightforward definition of transaction using
  # {::Carb::Flow::Steps::Step} only
  class Compose < Transaction
    private

    attr_reader :services_or_lambdas

    public

    # @param services_or_lambdas [Array] array of mixed {::Proc} and
    #   {::Carb::Service}
    def initialize(
      *services_or_lambdas,
      steps:   ::Carb::Steps::All,
      actions: ActionList.new
    )
      super(steps: steps, actions: actions)
      @services_or_lambdas = services_or_lambdas
    end

    protected

    def setup(**args)
      services_or_lambdas.each do |service_or_lambda|
        step(service_or_lambda)
      end
    end
  end
end
