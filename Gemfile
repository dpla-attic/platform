source 'https://rubygems.org'

gem 'rails', '3.2.8'
gem 'pg', :require => 'pg'
gem 'devise', '2.1.2'
gem 'jquery-rails'
gem 'dpla_search_api_v1', :path => 'v1'
# Reminder: Api-specific gems belong in v1.gemspec
gem 'turnout'  #can this be moved to v1.gemspec?
gem 'dpla_contentqa', :path => 'contentqa'
gem 'httparty'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
  gem 'twitter-bootstrap-rails'
  gem 'less'
end

gem 'rspec-rails', :group => [:test, :development]

group :test do
  gem 'rake'
  gem 'database_cleaner'
  gem 'cucumber-rails', :require => false
end
