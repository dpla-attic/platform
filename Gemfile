source 'https://rubygems.org'

gem 'rails', '~> 3.2.22'
gem 'unicorn', '~> 4.8.3'
gem 'rubygems-bundler', '~> 1.4.3'
gem 'pg', :require => 'pg'
gem 'sqlite3'  
gem 'devise', '~> 2.1.2'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'dpla_search_api_v1', :path => 'v1'
gem 'dpla_contentqa', :path => 'contentqa'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'jquery-tablesorter'
gem 'daemons'
gem 'rubyzip', '~> 1.1.6', :require => 'zip'

# twitter-bootstrap-rails can have problems finding itself when it is in the assets group
gem 'twitter-bootstrap-rails', '~> 2.2.8'
gem 'turnout'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
  gem 'less-rails'
end

group :test do
  gem 'database_cleaner'
  gem 'cucumber-rails', :require => false
end

group :test, :development do
  gem 'rake'
  gem 'rspec-rails'
  gem 'awesome_print'

  gem 'pry'
  gem 'pry-doc'
  gem 'pry-rails'
end


