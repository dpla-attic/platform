require 'v1/standard_dataset'
require 'v1/repository'

namespace :v1 do

  # NOTE: Any task that makes calls to Tire, must pass the :environment symbol in the task()
  # call so the Tire initializer gets called.

  desc "Tests river by posting test doc to CouchDB and verifying it in ElasticSearch"
  task :test_river => :environment do
    V1::StandardDataset.test_river
  end

  desc "Updates existing ElasticSearch schema *without* deleting the current index"
  task :update_search_schema => :environment do
    V1::StandardDataset.update_schema
  end

  desc "Re-creates ElasticSearch index, schema, river"
  task :recreate_search_index => :environment do
    V1::StandardDataset.recreate_index!
  end

  desc "Re-creates ElasticSearch index, schema, river and re-populates index with test dataset"
  task :recreate_search_env => :environment do
    V1::StandardDataset.recreate_env!
  end

  desc "Creates new ElasticSearch river"
  task :recreate_river do
    V1::StandardDataset.recreate_river!
  end

  desc "Deletes ElasticSearch river"
  task :delete_river do
    V1::StandardDataset.delete_river
  end

  desc "Gets ElasticSearch river status"
  task :river_status do
    puts V1::StandardDataset.river_status
  end

  desc "Gets ElasticSearch search cluster status"
  task :search_status do
    puts V1::StandardDataset.service_status
  end

  desc "Gets number of docs in search index"
  task :search_doc_count do
    puts V1::StandardDataset.doc_count
  end

  desc "Displays the ElasticSearch search_endpoint the API is configured to use"
  task :search_endpoint do
    puts V1::Config.search_endpoint
  end

  desc "Displays the schema that ElasticSearch is currently using, according to ElasticSearch."
  task :search_schema => :environment do
    puts V1::StandardDataset.search_schema
  end

  desc "Show API 'is_valid?' auth for a key"
  task :show_api_auth, [:key] do |t, args|
    puts "Authenticated?: #{  V1::Repository.authenticate_api_key args.key }"
  end
  
  desc "Displays the CouchDB repository_endpoint the API is configured to use"
  task :repo_endpoint do
    puts 'http://' + V1::Repository.reader_cluster_database
  end

  desc "Gets CouchDB repository status"
  task :repo_status do
    puts V1::Repository.service_status
  end

  desc "Creates new CouchDB repository database"
  task :recreate_repo_database do
    V1::Repository.recreate_doc_database
    V1::Repository.recreate_users
  end

  desc "Creates new CouchDB auth token database"
  task :recreate_repo_api_key_database do
    V1::Repository.recreate_api_keys_database
    V1::Repository.create_api_auth_views
  end
  
  desc "Imports test API keys into auth token database"
  task :import_test_api_keys, [:owner] do |t, args|
    V1::Repository.import_test_api_keys(args.owner)
  end
  
  desc "Re-creates read-only CouchDB user and re-assigns roles"
  task :recreate_repo_users do
    V1::Repository.recreate_users
  end
  
  desc "Gets number of docs in repository"
  task :repo_doc_count do
    puts V1::Repository.doc_count
  end

  desc "Re-creates CouchDB database, users, river and re-populates Couch with test dataset"
  task :recreate_repo_env do
    V1::Repository.recreate_env(true)
  end

  desc "Gets number of docs in search index and repository"
  task :doc_counts do
    puts "Search docs    : #{ V1::StandardDataset.doc_count }"
    puts "Repo docs/views: #{ V1::Repository.doc_count }" 
  end


end
