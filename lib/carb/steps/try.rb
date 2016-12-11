require "carb-core"
require "carb/service"
require "carb/monads"

module Carb::Steps
  # Run the supplied service with a {::Carb::Monads::Try} monad
  class Try
    include ::Carb::Service

    # Run #call on the passed service with given args
    # @param service [::Carb::Service]
    # @param args [Hash{Symbol => Object}] arguments to be passed to service
    #   when called
    # @params exceptions [Exception] by default is empty and it catches
    #   {StandardError} automatically. If an array of exceptions are specified,
    #   only those will be caught
    # @return [::Carb::Monads::Try, ::Carb::Monads::Either,
    #   ::Carb::Monads::Maybe] monad holding the result value if service is
    #   successful, if failure it returns the failing monad, however if Try
    #   catches an exception a {::Carb::Monads::Try::Failure} is returned,
    #   holding the exception
    def call(service:, args:, exceptions: [])
      monad = ::Carb::Monads::Try(*exceptions) { service.(**args) }

      monad.bind { |service_monad| service_monad }
    end
  end
end
