require "carb"

module Carb::Steps
  # Basic interface which must be adhered to if you are implementing new steps
  module Base
    # This method is required for any kind of step service. Must accept
    # **at least** service and args and must adhere to {::Carb::Service}
    # @param service [::Carb::Service]
    # @param args [Hash{Symbol => Object}] arguments to be passed to service
    #   when called
    # @return a monad
    def call(service:, args:)
      raise NotImplementedError, "Must implement #call"
    end
  end
end
