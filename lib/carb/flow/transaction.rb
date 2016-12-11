require "carb/flow"
require "carb/steps"
require "carb/service"
require "carb/monads"
require "carb/monads/success_matcher"

module Carb::Flow
  # TODO: Add wisper to Carb::Service? (or stick to Steps? Or transaction only?)
  class Transaction
    include ::Carb::Service
    Action = Struct.new(:name, :service, :args)

    protected

    attr_reader :steps
    attr_reader :actions

    public

    # @param steps [Hash{ Symbol => ::Carb::Service }]
    def initialize(steps: ::Carb::Steps::All)
      @steps   = steps
      @actions = []
    end

    def call(**args)
      # TODO: Extract an ActionList and Action class to deal with whole action
      #   resolution
      execute_each_action(args) do |result_monad, is_last|
        return result_monad if is_last

        extract_on_success_or_exit(result_monad) { |_| return result_monad }
      end
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

    def execute_each_action(initial_args)
      result_monad = ::Carb::Monads.monadize(initial_args)

      actions.each_with_index do |action, index|
        result_monad = execute_action(action, result_monad)
        yield(result_monad, ((index + 1) == actions.size))
      end
    end

    private

    def step_names
      @step_names ||= steps.keys
    end

    def append_action(step_name, service_name, **args)
      self.actions << Action.new(step_name, service_name, args)
    end

    def execute_action(action, result_monad)
      step      = steps[action.name]
      service   = send(action.service)
      step_args = action.args

      step.(service: service, args: result_monad.value, **step_args)
    end

    def extract_on_success_or_exit(result_monad, &block)
      ::Carb::Monads::SuccessMatcher.(result_monad) do |match|
        match.success { |value| value }
        match.failure(&block)
      end
    end
  end
end
