$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "contentqa/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dpla_contentqa"
  s.version     = Contentqa::VERSION
  s.authors     = ["Jeffrey Licht", "Miguel Alatorre", "Brian 'Phunk' Gadoury"]
  s.email       = ["jeff@podconsulting.com", "miguel@endpoint.com", "bgadoury@endpoint.com"]
  s.homepage    = "http://dp.la"
  s.summary     = "Support QA for content being ingested into the DPLA"
  s.description = "Support QA for content being ingested into the DPLA"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.11"
  s.add_dependency "httparty"
  s.add_dependency "twitter-bootstrap-rails"
  s.add_dependency "couchrest", '1.1.3'
  s.add_dependency "delayed_job", "~> 3.0.4"
  s.add_dependency "delayed_job_active_record", "~> 0.3.0"

end
