# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'servitude/version'

Gem::Specification.new do |spec|
  spec.name          = "servitude"
  spec.version       = Servitude::VERSION
  spec.authors       = ["Jason Harrelson"]
  spec.email         = ["jason@lookforwardenterprises.com"]
  spec.summary       = %q{A set of utilities to aid in building multithreaded Ruby servers utilizing Celluloid.}
  spec.description   = %q{A set of utilities to aid in building multithreaded Ruby servers utilizing Celluloid.  See README for more details.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency "celluloid", "~> 0"
  spec.add_dependency "hooks", "~> 0"
  spec.add_dependency "oj", "~> 2"
  spec.add_dependency "rainbow", "~> 2"
  spec.add_dependency "trollop", "~> 2"
  spec.add_dependency "yell", "~> 1"
end
