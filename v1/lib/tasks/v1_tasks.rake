namespace :v1 do

  desc "Creates new ElasticSearch index and populates it with the standard dataset"
  task :recreate_search_index => :environment do
    require 'v1/standard_dataset'
    V1::StandardDataset.recreate_index!
  end

  desc "Gets ES search cluster status"
  task :search_status do
    endpoint = V1::Config.get_search_endpoint
    # silly curl arguments to suppress the progress bar but let errors through
    puts %x( curl #{endpoint} -s -S )
  end

  desc "Diplays the ElasticSearch search_endpoint the API is configured to use"
  task :search_endpoint do
    puts V1::Config.get_search_endpoint
  end


  desc "Diplays the CouchDB repository_endpoint the API is configured to use"
  task :repository_endpoint do
    puts V1::Config.get_repository_endpoint
  end

  desc "Creates new CouchDB database and populates it with the standard dataset"
  task :recreate_repo_database => :environment do
    require 'v1/couchdb'
    V1::Couchdb.recreate_database!
  end


  desc "Verify all required V1 API config files exist"
  task :check_config do
    if Dpla.check_config( __FILE__, %w( config/elasticsearch/elasticsearch_pointer.yml ) )
      puts "OK. All required V1 API config files present."
    end
  end

  def get_json(file)
    IO.read File.expand_path("../../../config/elasticsearch/json/#{file}", __FILE__)
  end

end
