require "carb/flow"
require "carb/flow/transaction"

module Carb::Flow
  # Holds data necessary to discover step, service and args to be executed
  Transaction::Action = Struct.new(:step_name, :service_name, :args)
end
