module V1

  module Config

    SEARCH_INDEX = 'dpla'
    REPOSITORY_DATABASE = SEARCH_INDEX

    def self.search_endpoint
      search_config = dpla['search']
      if search_config && search_config['endpoint']
        search_config['endpoint']
      else
        "http://0.0.0.0:9200"
      end
    end

    def self.dpla
      #TODO: memoize
      config_file = File.expand_path("../../../config/dpla.yml", __FILE__)
      required_config_headers = %w( read_only_user search repository )

      raise "No config file found at #{config_file}" unless File.exists? config_file 
      dpla_config = YAML.load_file(config_file)

      if dpla_config && (dpla_config.keys - required_config_headers).empty?
        return dpla_config
      else
        raise "Consult dpla.yml.example. Missing proper values in: #{config_file}"
      end
    end

    def self.initialize_tire
      Tire::Configuration.url(search_endpoint)
      Tire::Configuration.wrapper(Hash)
      logfile = File.expand_path('../../../../var/log/elasticsearch.log', __FILE__)
      Tire.configure { logger logfile, :level => 'debug' }
      Tire::Model::Search.index_prefix("test_") if Rails.env.test?
    end

  end

end
