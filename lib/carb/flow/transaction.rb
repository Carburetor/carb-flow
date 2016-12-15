require "wisper"
require "carb/flow"
require "carb/steps"
require "carb/service"
require "carb/monads"
require "carb/monads/success_matcher"

module Carb::Flow
  # TODO: Add wisper to Carb::Service? (or stick to Steps? Or transaction only?)
  #   probably to steps is the best idea (leaves the services uncluttered), but
  #   discuss with Dave
  # TODO: Refactor code to use `carb` and not `carb-core` when requiring
  class Transaction
    include ::Carb::Service
    include ::Wisper::Publisher

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

      args_monad = ::Carb::Monads.monadize(args)

      execute_actions(args_monad)
    end

    def method_missing(method_name, *args, &block)
      if step_names.include?(method_name.to_sym)
        append_action(method_name.to_sym, *args)
      else
        super
      end
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

    def execute_actions(result_monad)
      actions.each do |action, is_last|
        result_monad, is_failure = execute_action(action, result_monad)

        return result_monad if is_last || is_failure
      end
    end

    def append_action(step_name, service_name, **args)
      self.actions << Action.new(step_name, service_name, args)
    end

    def step_names
      @step_names ||= steps.keys
    end

    def execute_action(action, result_monad)
      broadcast_step_start(action)

      result     = invoke_step(action)
      is_failure = failure?(result)

      broadcast_step_end(action)

      return result, is_failure
    end

    def invoke_step(action)
      step      = get_step(action)
      service   = get_service(action)
      step_args = get_args(action)

      step.(service: service, args: result_monad.value, **step_args)
    end

    def broadcast_step_start(action)
      # broadcast(:step_start, action.step_name, action.)
    end

    def failure?(result_monad)
      ::Carb::Monads::SuccessMatcher.(result_monad) do |match|
        match.success { |_| true }
        match.failure { |_| false }
      end
    end

    def get_step(action)
      steps[action.step_name]
    end

    def get_service(action)
      send(action.service_name)
    end

    def get_args(action)
      action.args
    end
  end
end

require "carb/flow/transaction/action"
require "carb/flow/transaction/action_list"
