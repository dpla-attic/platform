module V1

  module Search

    ELASTICSEARCH_POINTER_PATH = 'config/elasticsearch/elasticsearch_pointer.yml'

    def self.get_search_config
      default_file = '/etc/elasticsearch/elasticsearch.yml'
      begin
        pointer_file = File.expand_path("../../../#{ELASTICSEARCH_POINTER_PATH}", __FILE__)

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
      config = YAML.load_file(get_search_config) || {}
      host = config['network.host'] || config['network.bind_host'] || '0.0.0.0'
      port = config['http.port'] || '9200'
      return "http://#{host}:#{port}"
    end

  end

end
