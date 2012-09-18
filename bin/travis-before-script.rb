#!/usr/bin/env ruby

require 'yaml'

####
puts "TRAVIS: Creating dpla_test database"
puts %x( psql -c 'create database dpla_test;' -U postgres )

####
yaml_file = "config/database.yml"

if File.exist? yaml_file
  raise "Refusing to overwrite pre-existing yaml file #{yaml_file}"
end

puts "TRAVIS: Creating #{yaml_file}"

File.open(yaml_file, 'w') do |f|
  f.write({'test' =>
            {'adapter' => 'postgresql', 'database' => 'dpla_test', 'username' => 'postgres' }
          }.to_yaml)
end

puts "TRAVIS: Done."
