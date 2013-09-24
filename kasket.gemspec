# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'kasket/version'

Gem::Specification.new do |s|
  s.name        = "kasket"
  s.version     = Kasket::Version::STRING
  s.authors     = ["Mick Staugaard",   "Eric Chapweske"]
  s.email       = ["mick@zendesk.com", "eac@zendesk.com"]
  s.homepage    = "http://github.com/zendesk/kasket"
  s.summary     = "A write back caching layer on active record"
  s.description = "puts a cap on your queries"
  s.license     = "Apache License Version 2.0"

  s.add_runtime_dependency("activerecord", ">= 2.3.6", "< 3.3")

  s.add_development_dependency("rake")
  s.add_development_dependency("bundler")
  s.add_development_dependency("appraisal", "~> 0.5")
  s.add_development_dependency("shoulda")
  s.add_development_dependency("shoulda-matchers", "~> 2.3.0")
  s.add_development_dependency("mocha")
  s.add_development_dependency("test-unit", "~> 2.5")

  s.files        = Dir.glob("lib/**/*") + %w(README.rdoc)
  s.test_files   = Dir.glob("test/**/*")
  s.require_path = 'lib'
end
