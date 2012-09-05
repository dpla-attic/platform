module V1

  module Search

    ELASTICSEARCH_POINTER_PATH = 'config/elasticsearch/elasticsearch_pointer.yml'

    def self.get_search_config
      begin
        pointer_file = File.expand_path("../../../#{ELASTICSEARCH_POINTER_PATH}", __FILE__)
        return YAML.load_file(pointer_file)['config_file']
      rescue Exception
        raise "Missing or invalid #{pointer_file}. Perhaps you forgot to copy the #{pointer_file}.example file and customize it to point to your elasticsearch.yml file?"
      end
    end

    def self.get_search_endpoint
      begin
        config_file = get_search_config
        config = YAML.load_file(config_file)
        host = config['network.host'] || config['network.bind_host'] || '0.0.0.0'
        port = config['http.port'] || '9200'
        return "http://#{host}:#{port}/"
      rescue Errno::ENOENT => e
        raise "Missing elasticsearch.yml specified in #{ELASTICSEARCH_POINTER_PATH}"
      end
    end

  end

end
