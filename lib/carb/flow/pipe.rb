require "carb"
require "carb/flow/duct"

module Carb::Flow
  # Allows very easy and straightforward definition of pipeline using
  # {::Carb::Flow::Steps::Step} only
  class Pipe < Pipeline
    private

    attr_reader :services_or_lambdas

    public

    # @param services_or_lambdas [Array] array of mixed {::Proc} and
    #   {::Carb::Service}
    def initialize(*services_or_lambdas, steps: nil, actions: nil)
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
