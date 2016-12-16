require "carb"
require "carb/flow/transaction"

module Carb::Flow
  # Holds data necessary to discover step, service and args to be executed
  Transaction::Action = Struct.new(:step_name, :name_or_lambda, :args) do
    def lambda?
      name_or_lambda.is_a?(::Proc)
    end
  end
end
