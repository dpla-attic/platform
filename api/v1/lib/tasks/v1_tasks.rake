require 'v1'

namespace :v1 do

  desc "Gets ES search cluster status"
  task :search_status do
    endpoint = V1::Search.get_search_endpoint
    # silly curl arguments to suppress the progress bar but let errors through
    puts `curl #{endpoint} -s -S`
  end

  desc "Diplays the ElasticSearch search_endpoint the API is configured to use"
  task :search_endpoint do
    puts V1::Search.get_search_endpoint
  end

  desc "Verify all required V1 API config files exist"
  task :check_config do
    require 'dpla'
    if Dpla.check_config( __FILE__, %w( config/elasticsearch/elasticsearch_pointer.yml ) )
      puts "OK. All required V1 API config files present."
    end
  end
end
