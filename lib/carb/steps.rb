require "carb/steps/step"
require "carb/steps/tee"

module Carb
  module Steps
    All = [
      Step,
      Tee
    ].map(&:new).freeze
  end
end

