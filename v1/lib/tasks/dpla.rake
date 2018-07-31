require 'v1/search_engine'
require 'v1/repository'
require 'v1/api_auth'

namespace :v1 do

  desc "Lists ElasticSearch indices"
  task :search_indices => :environment do
    V1::SearchEngine.display_indices
  end

  desc "Gets ElasticSearch search cluster status"
  task :search_status do
    puts V1::SearchEngine.service_status
  end

  desc "Gets ElasticSearch search shards and statuses"
  task :search_shard_status => :environment do
    V1::SearchEngine.display_shard_status
  end

  desc "Gets number of docs in search index"
  task :search_doc_count do
    puts V1::SearchEngine.doc_count
  end

  desc "Displays the ElasticSearch search_endpoint the API is configured to use"
  task :search_endpoint do
    puts V1::Config.search_endpoint
  end

  desc "Displays the current schema in ElasticSearch, according to ElasticSearch."
  task :search_schema => :environment do
    puts V1::SearchEngine.search_schema
  end

  desc "Show API key by [key_id] or [email]"
  task :show_api_auth, [:key] do |t, args|
    puts (V1::ApiAuth.show_api_auth(args.key) || 'not found').to_s
  end
  
  desc "Toggle the disabled status for an API key"
  task :toggle_api_auth, [:key] => :environment do |t, args|
    key = V1::ApiAuth.toggle_api_auth(args.key)
    puts "API key is now: #{key.disabled? ? 'Disabled' : 'Enabled' }"
  end
  
  desc "Deletes cached API auth for a single api_key"
  task :clear_cached_api_auth, [:key] => :environment do |t, args|
    previous = V1::ApiAuth.clear_cached_auth(args.key)
    puts "Done. Cached value was: #{previous || 'nil'}"
  end
  
  desc "Displays the CouchDB repository_endpoint the API is configured to use"
  task :repo_endpoint do
    puts V1::Repository.reader_cluster_database.to_s
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
  
  desc "Re-creates read-only CouchDB user and re-assigns roles"
  task :recreate_repo_users do
    V1::Repository.recreate_users
  end
  
  desc "Gets number of docs in repository"
  task :repo_doc_count do
    puts V1::Repository.doc_count
  end

  desc "Re-creates CouchDB database, users, and API keys"
  task :recreate_repo_env => :environment do
    V1::Repository.recreate_env
  end

  desc "Gets number of docs in search index and repository"
  task :doc_counts do
    puts "Search docs    : #{ V1::SearchEngine.doc_count }"
    puts "Repo docs/views: #{ V1::Repository.doc_count }" 
  end

end
