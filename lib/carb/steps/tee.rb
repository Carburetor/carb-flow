require "carb-core"
require "carb-service"
require "carb-service/monads"

module Carb::Steps
  # Run the supplied service and return the passed argument wrapped in a
  # {::Carb::Monads::Monad}
  class Tee
    include ::Carb::Service

    # Run #call on the passed service with given args
    # @param service [::Carb::Service]
    # @param args [Hash{Symbol => Object}] arguments to be passed to service
    #   when called
    # @return [::Carb::Monads::Monad] the passed `args`, wrapped in a
    #   {::Carb::Monads::Result::Success} monad if successful, otherwise
    #   wrapped in a {::Carb::Monads::Result::Failure}
    def call(service:, args:)
      service.(**args)
    end
  end
end
