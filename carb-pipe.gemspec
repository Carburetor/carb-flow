# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "carb/pipe/version"

Gem::Specification.new do |spec|
  spec.name          = "carb-pipe"
  spec.version       = Carb::Pipe::VERSION
  spec.authors       = ["Fire-Dragon-DoL"]
  spec.email         = ["francesco.belladonna@gmail.com"]

  spec.summary       = %q{Pipe operator for service objects}
  spec.description   = %q{Utility for building chain of services like pipe
    operator and to handle failures in between chains}
  spec.homepage      = "https://github.com/Carburetor/carb-pipe"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://gems.carb.io"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-monads", "~> 0.2.1"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake",    "~> 11.0"
  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "pry-byebug"
end
