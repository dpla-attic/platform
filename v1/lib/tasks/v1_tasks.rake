require 'v1/standard_dataset'
require 'v1/repository'

namespace :v1 do

  # NOTE: Any task that makes calls to Tire, must pass the :environment symbol in the task()
  # call so the Tire initializer gets called.

  desc "Tests river by posting test doc to CouchDB and verifying it in ElasticSearch"
  task :test_river => :environment do
    V1::StandardDataset.test_river
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
    V1::StandardDataset.delete_river!
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
  task :search_schema, [:resource] do |t, args|
    puts V1::StandardDataset.search_schema(args.resource)
  end

  desc "Displays the CouchDB repository_endpoint the API is configured to use"
  task :repo_endpoint do
    puts 'http://' + V1::Repository.reader_cluster_database
  end

  desc "Gets CouchDB repository status"
  task :repo_status do
    puts V1::Repository.service_status
  end

  desc "Creates new CouchDB database"
  task :recreate_repo_database do
    V1::Repository.recreate_database!
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
  task :recreate_repo_env => :environment do
    V1::Repository.recreate_env!
  end

end
