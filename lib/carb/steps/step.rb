require "carb-core"
require "carb-service"

module Carb::Steps
  # Simply run the supplied service
  class Step
    include ::Carb::Service

    # Run #call on the passed service with given args
    # @param service [::Carb::Service]
    # @param args [Hash{Symbol => Object}] arguments to be passed to service
    #   when called
    # @return [::Carb::Monads::Monad]
    def call(service:, args:)
      service.(**args)
    end
  end
end
