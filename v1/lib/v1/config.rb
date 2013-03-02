module V1

  module Config

    #TODO: move these two to their respective modules
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
      required = %w( read_only_user )

      raise "No config file found at #{config_file}" unless File.exists? config_file 
      dpla_config = YAML.load_file(config_file)

      # Make sure we got all required keys (extra keys are fine)
      if dpla_config && (dpla_config.keys & required).sort == required.sort
        dpla_config
      else
        raise "Consult dpla.yml.example. Missing required values in: #{config_file}"
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
