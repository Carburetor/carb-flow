require "carb"
require "carb/steps"
require "carb/flow/transaction"

module Carb::Flow
  class Pipe < Transaction
    def initialize(steps: ::Carb::Steps::All, &block)
      raise ArgumentError, "Step definition required" if block.nil?

      super(steps: steps)

      @block = block
    end

    protected

    def setup(**args)
      instance_eval(&@block)
    end
  end
end
