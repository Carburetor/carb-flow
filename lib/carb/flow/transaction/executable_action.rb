require "carb/flow"
require "carb/flow/transaction"
require "carb/service"

module Carb::Flow
  # Provides functionality to execute a {::Carb::Flow::Transaction::Action}
  Transaction::ExecutableAction = Struct.new(:step, :service, :step_args) do
    include ::Carb::Service

    def call(**args)
      step.(service: service, args: args, **step_args)
    end
  end
end
