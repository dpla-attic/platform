require 'inifile'

module V1

  module Config

    SEARCH_INDEX = 'dpla'.freeze
    REPOSITORY_DATABASE = SEARCH_INDEX

    def self.get_search_endpoint
      search_config = dpla['search']
      if search_config.nil? || search_config['endpoint'].nil? 
        endpoint = "http://0.0.0.0:9200"
      else
        endpoint = search_config['endpoint']
      end
      endpoint
    end

    def self.dpla
      #TODO: test
      dpla_config_path = File.expand_path("../../../config/dpla.yml", __FILE__)

      raise "No config file found at #{dpla_config_path}" unless File.exists? dpla_config_path 
      dpla_config = YAML.load_file(dpla_config_path)
      required_config_headers = [
        "read_only_user",
        "search",
        "repository"
      ]

      if dpla_config && (dpla_config.keys - required_config_headers).empty?
        return dpla_config
      else
        raise "Consult dpla.yml.example. Missing proper values in: #{dpla_config_path}"
      end
    end

    def self.initialize_tire
      #TODO: test
      Tire::Configuration.url(get_search_endpoint)
      Tire::Configuration.wrapper(Hash)
      logfile = File.expand_path('../../../../var/log/elasticsearch.log', __FILE__)
      Tire.configure { logger logfile, :level => 'debug' }
      Tire::Model::Search.index_prefix("test_") if Rails.env.test?
    end

  end

end
