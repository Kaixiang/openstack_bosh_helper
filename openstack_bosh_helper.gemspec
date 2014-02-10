# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstack_bosh_helper/version'

Gem::Specification.new do |spec|
  spec.name          = "openstack_bosh_helper"
  spec.version       = OpenstackBoshHelper::VERSION
  spec.authors       = ["Kai Xiang"]
  spec.email         = ["kxiang@pivotallabs.com"]
  spec.description   = %q{This cli(script) helps you to deploy microbosh/cf to bluebox openstack env}
  spec.summary       = %q{CLI helper to deploy microbosh/cf to bluebox openstack env}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.9.0"
  spec.add_development_dependency "mothership"
  spec.add_development_dependency "highline"
  spec.add_development_dependency "fog", "~>1.20.0"

end
