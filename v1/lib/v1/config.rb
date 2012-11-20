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

    def self.get_repository_admin
      #TODO test
      dpla_config = get_dpla_config
      admin = dpla_config['couch_db']['admin']
      password = dpla_config['couch_db']['password']
      return "#{admin}:#{password}"
    end

    def self.get_repository_read_only_password
      dpla_config = get_dpla_config
      dpla_config['elasticsearch']['password']
    end

    def self.get_repository_read_only_username
      dpla_config = get_dpla_config
      dpla_config['elasticsearch']['username']
    end

    def self.get_dpla_config
      #TODO: test
      begin
        dpla_config_path = File.expand_path("../../../config/dpla.yml", __FILE__)
        if File.exists? dpla_config_path
          dpla_config = YAML.load_file(dpla_config_path)
          required_config_params = ["couch_db", "elasticsearch"]
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

    def self.get_repository_host
      #TODO: test
      config = get_repository_config
      if config.nil?
        host = '127.0.0.1'
        port = '5984'
      else
        host = config['httpd']['bind_address']
        port = config['httpd']['port']
      end
      "#{host}:#{port}"
    end

    def self.get_repository_endpoint
      #TODO do we need this method?
      "http://#{get_repository_host}"
    end

    def self.get_repository_read_only_endpoint
      "http://#{get_repository_read_only_username}:#{get_repository_read_only_password}@#{get_repository_host}"
    end

    def self.get_repository_admin_endpoint
      "http://#{get_repository_admin}@#{get_repository_host}"
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
