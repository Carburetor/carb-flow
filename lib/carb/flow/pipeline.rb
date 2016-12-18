require "wisper"
require "carb"
require "carb/steps"
require "carb/service"
require "carb/service/lambda"
require "carb/monads"

module Carb::Flow
  class Pipeline
    include ::Carb::Service
    include ::Wisper::Publisher

    Error      = Class.new(::StandardError)
    EmptyError = Class.new(Error)
    EMPTY_MSG  = "Pipeline must have at least one step".freeze

    protected

    attr_reader :steps
    attr_reader :actions

    public

    # @param steps [Hash{ Symbol => ::Carb::Service }]
    # @param actions [ActionList] optional action list handler
    def initialize(steps: ::Carb::Steps::All, actions: ActionList.new)
      @steps   = steps
      @actions = actions
    end

    def call(**args)
      setup(**args)

      raise EmptyError, EMPTY_MSG if actions.empty?

      args_monad = ::Carb::Monads.monadize(args)
      perform(args_monad)
    end

    def method_missing(method_name, *args, &block)
      mth = method_name.to_sym
      return append_action(mth, *args) if step_names.include?(mth)

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      step_names.include?(method_name.to_sym) || super
    end

    protected

    # Can be overwritten to generate steps in subclasses
    # @params args [Hash{ Symbol => Object }] arguments as supplied to {#call}
    def setup(**args)
    end

    private

    def perform(args_monad)
      broadcast(:start, self)
      result_monad, is_failure = execute_actions(args_monad)
      broadcast_finish(is_failure)

      result_monad
    end

    def execute_actions(result_monad)
      actions.each do |action, is_last|
        result_monad, is_failure = execute_action(action, result_monad)

        return result_monad, is_failure if is_last || is_failure
      end
    end

    def append_action(step_name, name_or_service_or_lambda, **args)
      step    = steps[step_name]
      service = get_service(name_or_service_or_lambda)

      self.actions << Action.new(step, service, args)
    end

    def step_names
      @step_names ||= steps.keys
    end

    def execute_action(action, result_monad)
      broadcast(:step_start, action, result_monad)

      result     = action.(**result_monad.value)
      is_failure = failure?(result)

      broadcast_step_finish(action, result, is_failure)

      return result, is_failure
    end

    # @param nsl [::Symbol, ::Carb::Service, ::Proc]
    # @return [::Carb::Service]
    def get_service(nsl)
      return nsl                              if nsl.is_a?(::Carb::Service)
      return send(nsl)                        if nsl.is_a?(::Symbol)
      return ::Carb::Service::Lambda.new(nsl) if nsl.is_a?(::Proc)

      raise ArgumentError, "step must be performed on Symbol, Lambda or Service"
    end

    def broadcast_finish(is_failure)
      return broadcast(:failure, self) if is_failure

      broadcast(:success, self)
    end

    def broadcast_step_finish(action, result, is_failure)
      broadcast(:step_failure, action, result) if is_failure

      broadcast(:step_success, action, result)
    end

    def failure?(result_monad)
      !::Carb::Monads.success_monad?(result_monad)
    end
  end
end

require "carb/flow/pipeline/action"
require "carb/flow/pipeline/action_list"
