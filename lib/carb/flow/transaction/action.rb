require "carb/flow"
require "carb/flow/transaction"

module Carb::Flow
  Transaction::Action = Struct.new(:step_name, :service_name, :args)
end
