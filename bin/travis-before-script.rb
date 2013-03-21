#!/usr/bin/env ruby

require 'yaml'

####
puts "TRAVIS: Creating dpla_test database"
puts %x( psql -c 'create database dpla_test;' -U postgres )
puts "TRAVIS: Done."

####
# Create the database config for the application
db_yaml_file = "config/database.yml"

if File.exist? db_yaml_file
  raise "Refusing to overwrite pre-existing database yaml file #{db_yaml_file}"
end

####
puts "TRAVIS: Creating #{db_yaml_file}"

File.open(db_yaml_file, 'w') do |f|
  f.write({'test' =>
            {'adapter' => 'postgresql', 'database' => 'dpla_test', 'username' => 'postgres' }
          }.to_yaml)
end

puts "TRAVIS: Done."

####
# Create the DPLA config file for securing couchDB and with read-only user for elastic search
dpla_config_file = "v1/config/dpla.yml"

if File.exist? dpla_config_file
  raise "Refusing to overwrite pre-existing dpla config yaml file #{dpla_config_file}"
end

####
puts "TRAVIS: Creating #{dpla_config_file}"
# Create the non-default-able values that Travis will need
File.open(dpla_config_file, 'w') do |f|
  f.write(
          {
            'repository' => {
              'reader' => {
                'user' => 'dpla',
                'pass' => 'es_password'
              }
            }
          }.to_yaml
          )
end

puts "TRAVIS: Done."

####
puts "TRAVIS: Running rake db:migrate"
puts %x( bundle exec rake --trace db:migrate )
puts "TRAVIS: Done."

