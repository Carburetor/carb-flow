require "carb"
require "carb/steps"
require "carb/flow/transaction"
require "carb/flow/transaction/action_list"

# TODO: Completely write Compose file, this implementation is copy-pasted from
# pipe
module Carb::Flow
  class Compose < Transaction
    private

    attr_reader :block

    public

    def initialize(steps: ::Carb::Steps::All, actions: ActionList.new, &block)
      raise ArgumentError, "Step definition required" if block.nil?

      super(steps: steps, actions: actions)

      @block = block
    end

    protected

    def setup(**args)
      instance_eval(&block)
    end
  end
end
