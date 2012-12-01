#!/usr/bin/env ruby

require 'yaml'

####
puts "TRAVIS: Creating dpla_test database"
puts %x( psql -c 'create database dpla_test;' -U postgres )

####

# Create the database config for the application
db_yaml_file = "config/database.yml"

if File.exist? db_yaml_file
  raise "Refusing to overwrite pre-existing database yaml file #{db_yaml_file}"
end

puts "TRAVIS: Creating #{db_yaml_file}"

File.open(db_yaml_file, 'w') do |f|
  f.write({'test' =>
            {'adapter' => 'postgresql', 'database' => 'dpla_test', 'username' => 'postgres' }
          }.to_yaml)
end

puts "TRAVIS: Done."

# Create the DPLA config file for securing couchDB and with read-only user for elastic search
dpla_yaml_file =  "v1/config/dpla.yml"

if File.exist? dpla_yaml_file
  raise "Refusing to overwrite pre-existing dpla config yaml file #{dpla_yaml_file}"
end

puts "TRAVIS: Creating #{dpla_yaml_file}"

File.open(dpla_yaml_file, 'w') do |f|
  f.write({
           'couch_read_only' =>
           { 'username' => 'dpla', 'password' => 'es_password' },
           'couch_admin' =>
           { 'username' => 'admin', 'password' => 'chonta', 'endpoint' => 'http://127.0.0.1:5984'}
          }.to_yaml)
end

puts "TRAVIS: Done"
