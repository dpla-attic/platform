source 'https://rubygems.org'

gem 'rails', '~> 3.2.22'
gem 'unicorn', '~> 4.8.3'
gem 'rubygems-bundler', '~> 1.4.3'
gem 'pg', '~> 0.17.1', :require => 'pg'
gem 'sqlite3', '~> 1.3.0'
gem 'devise', '~> 2.1.2'
gem 'jquery-rails', '~> 3.1.0'
gem 'jquery-ui-rails', '~> 5.0'
gem 'dpla_search_api_v1', :path => 'v1'
gem 'public_suffix', '~> 1.4.0'

# twitter-bootstrap-rails can have problems finding itself when it is in the assets group
gem 'twitter-bootstrap-rails', '~> 2.2.8'
gem 'turnout', '~> 2.4.0'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '~> 3.0.0'
  gem 'less-rails', '~> 2.6.0'
end

group :test do
  gem 'database_cleaner', '~> 1.5.0'
  gem 'cucumber-rails', '~> 1.4.0', :require => false
end

group :test, :development do
  gem 'rake', '~> 11.3.0'
  gem 'rspec-rails', '~> 2.14.1'
  gem 'awesome_print', '~> 1.7.0'

  gem 'pry'
  gem 'pry-doc'
  gem 'pry-rails'
end
