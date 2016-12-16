require "carb"
require "carb/flow/transaction"
require "carb/flow/transaction/action"

module Carb::Flow
  class Transaction::ActionList
    private

    attr_reader :list

    public

    def initialize(action_list = nil)
      @list = extract_list_or_empty(action_list)
    end

    def <<(action)
      unless action.is_a?(::Carb::Flow::Transaction::Action)
        raise TypeError, "action must be an Action"
      end

      list << action
    end

    def to_a
      list
    end

    # @yieldparam action [Action]
    # @yieldparam is_last [Boolean] if it's the last action of the list
    def each
      list.each_with_index do |action, index|
        yield(action, ((index + 1) == list.size))
      end
    end

    def empty?
      list.empty?
    end

    private

    def extract_list_or_empty(list)
      return [] if list.nil?

      list.to_a
    end
  end
end
