require "wisper"
require "carb/flow"
require "carb/steps"
require "carb/service"
require "carb/monads"
require "carb/monads/success_matcher"
require "carb/flow/transaction/action"
require "carb/flow/transaction/action_list"
require "carb/flow/transaction/executable_action"

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

      broadcast(:start, self)
      execute_actions(args_monad)
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

    def execute_actions(result_monad)
      actions.each do |action, is_last|
        result_monad, is_failure = execute_action(action, result_monad)

        broadcast_finish(is_failure) if is_last || is_failure
        return result_monad          if is_last || is_failure
      end
    end

    def append_action(step_name, service_name, **args)
      self.actions << Action.new(step_name, service_name, args)
    end

    def step_names
      @step_names ||= steps.keys
    end

    def execute_action(action, result_monad)
      broadcast(:step_start, action, result_monad.value)

      executable         = build_executable(action)
      result, is_failure = run_executable(executable, result_monad)

      broadcast_step_finish(action, result, is_failure)

      return result, is_failure
    end

    def build_executable(action)
      step    = steps[action.step_name]
      service = send(action.service_name)
      args    = action.args

      ExecutableAction.new(step, service, args)
    end

    def run_executable(executable, result_monad)
      result     = executable.(**result_monad.value)
      is_failure = failure?(result)

      return result, is_failure
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
      ::Carb::Monads::SuccessMatcher.(result_monad) do |match|
        match.success { |_| true }
        match.failure { |_| false }
      end
    end
  end
end
