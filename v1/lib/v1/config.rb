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
      config_file = File.expand_path("../../../config/dpla.yml", __FILE__)
      raise "No config file found at #{config_file}" unless File.exists? config_file
      YAML.load_file(config_file)
    end

    def self.initialize_tire
      Tire::Configuration.url(search_endpoint)
      Tire::Configuration.wrapper(Hash)
      logfile = File.expand_path('../../../../var/log/elasticsearch.log', __FILE__)
      Tire.configure { logger logfile, :level => 'debug' }
    end

  end

end
