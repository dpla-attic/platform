require 'v1'

namespace :v1 do

  desc "Gets ES search cluster status"
  task :search_status do
    endpoint = V1::Search.get_search_endpoint
    # silly curl arguments to suppress the progress bar but let errors through
    puts %x( curl #{endpoint} -s -S )
  end

  desc "Diplays the ElasticSearch search_endpoint the API is configured to use"
  task :search_endpoint do
    puts V1::Search.get_search_endpoint
  end

  desc "Creates new ElasticSearch index and populates it with data from api/v1/json/"
  task :create_test_search_index do
    search_endpoint = V1::Search.get_search_endpoint
    puts %x( curl -XPOST #{search_endpoint}/dpla -d '#{get_json('index-create')}' )
    puts %x( curl -XPUT  #{search_endpoint}/dpla/item/1 -d '#{get_json('item1-create')}' )
    puts %x( curl -XPUT  #{search_endpoint}/dpla/item/2 -d '#{get_json('item2-create')}' )
  end

  desc "Verify all required V1 API config files exist"
  task :check_config do
    require 'dpla'
    if Dpla.check_config( __FILE__, %w( config/elasticsearch/elasticsearch_pointer.yml ) )
      puts "OK. All required V1 API config files present."
    end
  end

  def get_json(file)
    IO.read File.expand_path("../../../config/elasticsearch/json/#{file}", __FILE__)
  end

end
