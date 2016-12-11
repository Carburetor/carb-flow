require "carb/steps/base"
require "carb/steps/step"
require "carb/steps/tee"
require "carb/steps/try"

module Carb
  module Steps
    All = {
      step: Step.new,
      tee:  Tee.new,
      try:  Try.new
    }.freeze
  end
end

