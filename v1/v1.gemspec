$:.push File.expand_path("../lib", __FILE__)

require "v1/version"

Gem::Specification.new do |s|
  s.name        = "dpla_search_api_v1"
  s.version     = V1::VERSION
  s.authors     = ["Brian 'Phunk' Gadoury"]
  s.email       = ["bgadoury@endpoint.com"]
  s.homepage    = "http://dp.la"
  s.summary     = "DPLA Search API V1"
  s.description = "DPLA Search API V1"
  s.requirements << "The host DPLA API rails application"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.md"]

  s.add_dependency "rails", "~> 3.2.12"
  s.add_dependency "json"
  s.add_dependency "tire", '0.5.7'
  s.add_dependency "couchrest", '1.1.3'
  s.add_dependency "httparty"

  s.add_development_dependency "rspec-rails"
end
