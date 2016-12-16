require "carb"
require "carb/service"
require "carb/steps/base"

module Carb::Steps
  # Simply run the supplied service
  class Step
    include ::Carb::Service
    include Base

    # Run #call on the passed service with given args
    # @param service [::Carb::Service]
    # @param args [Hash{Symbol => Object}] arguments to be passed to service
    #   when called
    # @return a monad
    def call(service:, args:)
      service.(**args)
    end
  end
end
