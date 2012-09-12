$:.push File.expand_path("../lib", __FILE__)

require "v1/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dpla_search_api_v1"
  s.version     = V1::VERSION
  s.authors     = ["Brian 'Phunk' Gadoury"]
  s.email       = ["bgadoury@endpoint.com"]
  s.homepage    = "TODO: DPLA"
  s.summary     = "DPLA Search API V1"
  s.description = "DPLA Search API V1"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  #  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency "pg"
  s.add_development_dependency "rspec-rails"
#  s.add_development_dependency "sqlite3"
  # s.add_dependency "jquery-rails"
end
