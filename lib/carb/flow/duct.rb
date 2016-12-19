require "carb"
require "carb/steps"
require "carb/flow/pipeline"
require "carb/flow/pipeline/action_list"

module Carb::Flow
  class Duct < Pipeline
    private

    attr_reader :block

    public

    def initialize(steps: nil, actions: nil, &block)
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
