#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

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

# TODO: Use a template file like dpla.yml.travis does
File.open(db_yaml_file, 'w') do |f|
  f.write({'test' =>
            {'adapter' => 'postgresql', 'database' => 'dpla_test', 'username' => 'postgres' }
          }.to_yaml)
end

puts "TRAVIS: Done."

####
source_config = "v1/config/dpla.yml.travis"
dest_config = source_config.sub /\.travis$/, ''
puts "TRAVIS: Copying #{source_config} to #{dest_config}"

if File.exist? dest_config
  raise "Refusing to overwrite pre-existing dpla config yaml file #{dest_config}"
end

FileUtils.cp source_config, dest_config

puts "TRAVIS: Done."

####
puts "TRAVIS: Running rake db:migrate"
puts %x( bundle exec rake --trace db:migrate )
puts "TRAVIS: Done."

