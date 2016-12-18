require "carb"
require "carb/flow/pipeline"
require "carb/service"

module Carb::Flow
  # Provides functionality to execute step for given service
  Pipeline::Action = Struct.new(:step, :service, :step_args) do
    include ::Carb::Service

    def call(**args)
      step.(service: service, args: args, **step_args)
    end
  end
end
