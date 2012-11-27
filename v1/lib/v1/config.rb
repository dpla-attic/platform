require 'inifile'

module V1

  module Config

    SEARCH_INDEX = 'dpla'.freeze
    REPOSITORY_DATABASE = SEARCH_INDEX

    def self.get_search_config
      #TODO: Refactor to look for ../../../config/elasticsearch/elasticsearch.yml or default to std location yml file
      default_file = '/etc/elasticsearch/elasticsearch.yml'
      begin
        pointer_file = File.expand_path("../../../config/elasticsearch/elasticsearch_pointer.yml", __FILE__)

        if File.exist? pointer_file
          custom_file = YAML.load_file(pointer_file)['config_file']

          if !File.exist? custom_file
            raise "Invalid path (#{custom_file}) for elasticsearch.yml specified in #{pointer_file}"
          end
          return custom_file
        elsif File.exist? default_file
          return default_file
        else
          raise "Missing elasticsearch pointer file #{pointer_file} and no default #{default_file} found."
        end
      end
    end

    def self.get_search_endpoint
      # Use the config file or supply reasonable defaults
      search_config ||= YAML.load_file(get_search_config) || {}
      host = search_config['network.host'] || search_config['network.bind_host'] || '0.0.0.0'
      port = search_config['http.port'] || '9200'
      return "http://#{host}:#{port}"
    end

    def self.get_repository_config
      #TODO: test
      # Look for local config (could be a symlink) or assume standard CouchDB defaults
      couchdb_ini = File.expand_path("../../../config/couchdb.ini", __FILE__)
      config = IniFile.load(couchdb_ini)
      if config.nil?
        Rails.logger.warn "No custom CouchDB config file found at #{couchdb_ini}. Using default values for address:port"
      end
      config
    end

    def self.dpla
      #TODO: test
      begin
        dpla_config_path = File.expand_path("../../../config/dpla.yml", __FILE__)
        if File.exists? dpla_config_path
          dpla_config = YAML.load_file(dpla_config_path)
          required_config_params = ["couch_admin", "couch_read_only"]
          if (dpla_config.keys - required_config_params).empty?
            return dpla_config
          else
            raise "The DPLA config file found at #{dpla_config_path} is lacking needed values"
          end
        else
         raise "No DPLA config file found at #{dpla_config_path}"
        end
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
