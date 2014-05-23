require 'v1/search_engine'
require 'v1/repository'
require 'v1/api_auth'

namespace :v1 do

  # NOTE: Any task that calls a method that internally makes calls to Tire, must pass
  # the :environment symbol in the task() call so the Tire initializer gets called.

  desc "Updates existing ElasticSearch schema *without* deleting the current index"
  task :update_search_schema => :environment do
    V1::SearchEngine.update_schema
  end

  desc "Deploys search index by updating dpla_alias and its river"
  task :deploy_search_index, [:index] => :environment do |t, args|
    raise "Missing required index argument to rake task" unless args.index
    V1::SearchEngine.deploy_index(args.index)
  end

  desc "Creates new ElasticSearch index"
  task :create_search_index => :environment do
    V1::SearchEngine.create_index
  end

  desc "Lists ElasticSearch indices"
  task :search_indices => :environment do
    V1::SearchEngine.display_indices
  end

  desc "Deletes the named ElasticSearch index. Requires 'really' as second param to confirm delete."
  task :delete_search_index, [:index,:really] => :environment do |t, args|
    if args.really != 'really'
      raise "Missing/incorrect 'really' parameter. Hint: It must be the string: really"
    end
    V1::SearchEngine.safe_delete_index(args.index)
  end

  desc "Creates new ElasticSearch index and river"
  task :create_search_index_with_river => :environment do
    V1::SearchEngine.create_index_with_river
  end

  desc "Creates new ElasticSearch index and river and *immediately* deploys it"
  task :create_and_deploy_index => :environment do
    if Rails.env.production?
      raise "Refusing to run create_and_deploy_index in production b/c it would deploy an empty index"
    end
    V1::SearchEngine.create_and_deploy_index
  end

  desc "Re-creates ElasticSearch river for the currently deployed index"
  task :recreate_river => :environment do
    V1::SearchEngine::River.recreate_river
  end

  desc "Creates new ElasticSearch river, pointed at $index (defaults to currently deployed index)"
  task :create_river, [:index,:river] => :environment do |t, args|
    V1::SearchEngine::River.create_river('index' => args.index, 'river' => args.river)
  end

  desc "Deletes ElasticSearch river named '#{V1::Config.river_name}'"
  task :delete_river do
    V1::SearchEngine::River.delete_river or puts "River does not exist, so nothing to delete"
  end

  desc "Displays the river's current indexing velocity"
  task :river_velocity, [:river] => :environment do |t, args|
    puts "River velocity: " + V1::SearchEngine::River.current_velocity(args.river)
  end

  desc "Lists ElasticSearch rivers"
  task :river_list => :environment do
    puts V1::SearchEngine::River.list_all
  end

  desc "Gets ElasticSearch river status"
  task :river_status do
    puts V1::SearchEngine::River.verify_river_status
  end

  desc "Gets ElasticSearch river last_sequence"
  task :river_last_sequence do
    puts V1::SearchEngine::River.last_sequence
  end

  desc "Tests river by posting test doc to CouchDB and verifying it in ElasticSearch"
  task :river_test => :environment do
    V1::SearchEngine::River.river_test
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

  desc "Displays the current schema as defined by the API. This is the canonical API schema."
  task :show_api_schema do
    puts JSON.pretty_generate(V1::Schema::ELASTICSEARCH_MAPPING)
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

  desc "Re-creates CouchDB database, users, API keys and river"
  task :recreate_repo_env => :environment do
    V1::Repository.recreate_env(true)
  end

  desc "Gets number of docs in search index and repository"
  task :doc_counts do
    puts "Search docs    : #{ V1::SearchEngine.doc_count }"
    puts "Repo docs/views: #{ V1::Repository.doc_count }" 
  end

end
