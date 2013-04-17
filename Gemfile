source 'https://rubygems.org'

gem 'rails', '3.2.12'
gem 'unicorn'
gem 'rubygems-bundler', '1.1.1'
gem 'pg', :require => 'pg'
gem 'sqlite3'  
gem 'devise', '2.1.2'
gem 'jquery-rails'
gem 'dpla_search_api_v1', :path => 'v1'
gem 'turnout'  #can this be moved to v1.gemspec?
gem 'dpla_contentqa', :path => 'contentqa'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
  gem 'twitter-bootstrap-rails'
  gem 'less-rails'
end

gem 'rspec-rails', :group => [:test, :development]

group :test do
  gem 'test-unit'
  gem 'ruby-prof'
  gem 'rake'
  gem 'database_cleaner'
  gem 'cucumber-rails', :require => false
end
