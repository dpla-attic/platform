require 'tire'

module V1

  module Config

    #TODO: move these two to their respective modules
    SEARCH_INDEX = 'dpla'
    REPOSITORY_DATABASE = SEARCH_INDEX

    def self.search_endpoint
      endpoint = dpla['search']['endpoint'] rescue 'http://127.0.0.1:9200'
      endpoint = (endpoint =~ /^http:\/\//i) ? endpoint : 'http://' + endpoint
    end

    def self.dpla
      #TODO: memoize
      #TODO: just handle Errno::ENOENT exception
      config_file = File.expand_path("../../../config/dpla.yml", __FILE__)
      raise "No config file found at #{config_file}" unless File.exists? config_file
      YAML.load_file(config_file)
    end

    def self.accept_any_api_key?
      # We are explicit here so only a bare:  true OR yes  will return true
      (dpla['api_auth'] && dpla['api_auth']['allow_all_keys'] === true)
    end

    def self.skip_key_auth_completely?
      # We are explicit here so only a bare:  true OR yes  will return true
      (dpla['api_auth'] && dpla['api_auth']['skip_key_auth_completely'] === true)
    end

    def self.initialize_tire
      Tire::Configuration.url(search_endpoint)
      Tire::Configuration.wrapper(Hash)
    end

    def self.enable_tire_logging(env)
      logfile = File.expand_path("../../../../var/log/elasticsearch-#{env}.log", __FILE__)
      Tire.configure { logger logfile, :level => 'info' }
    end

  end

end
