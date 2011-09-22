# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "api_bee/version"

Gem::Specification.new do |s|
  s.name        = "api_bee"
  s.version     = ApiBee::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ismael Celis"]
  s.email       = ["ismaelct@gmail.com"]
  s.homepage    = "https://github.com/ismasan/ApiBee"
  s.description     = %q{Small Ruby client for discoverable, paginated JSON APIs}
  s.summary = %q{API Bee is a small client / spec for a particular style of JSON API. Use Hash adapter for local data access.}

  s.rubyforge_project = "api_bee"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
