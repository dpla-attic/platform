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
      config_file = File.expand_path("../../../config/dpla.yml", __FILE__)
      begin
        return YAML.load_file(config_file)
      rescue => e
        raise "Error loading config file #{config_file}: #{e}"
      end
    end

    def self.accept_any_api_key?
      # We are explicit here so only a bare:  true OR yes  will return true
      (dpla['api_auth'] && dpla['api_auth']['allow_all_keys'] === true)
    end

    def self.skip_key_auth_completely?
      # We are explicit here so only a bare:  true OR yes  will return true
      (dpla['api_auth'] && dpla['api_auth']['skip_key_auth_completely'] === true)
    end

    def self.initialize_search_engine
      Tire::Configuration.url(search_endpoint)
      Tire::Configuration.wrapper(Hash)
    end

    def self.configure_search_logging(env)
      logfile = File.expand_path("../../../../var/log/elasticsearch-#{env}.log", __FILE__)
      level = (dpla['search']['log_level'] || 'info') rescue 'info'
      Tire::Configuration.logger(logfile, :level => level)
    end
    
    def self.memcache_servers
      dpla['caching']['memcache_servers'] rescue []
    end

    def self.email_from_address
      dpla['api']['email_from_address'] rescue 'dpla_default_sender@example.com'
    end

    def self.cache_results
      dpla['caching']['cache_results'] rescue false
    end

    def self.cache_store
      return :null_store unless cache_results

      cache_store = dpla['caching']['store']

      if cache_store == 'dalli_store'
        if memcache_servers.nil? || !memcache_servers.any?
          raise "No memcache servers specified for cache_store: dalli_store"
        end
        store = cache_store.to_sym, *memcache_servers, { :namespace => 'V2', :compress => true}
      elsif cache_store == 'file_store'
        store = cache_store.to_sym, "tmp/api-cache"
      elsif cache_store == 'null_store'
        store = cache_store.to_sym
      else
        store = :null_store
      end
      
      store
    end
    
  end

end
