require_relative 'config'
require_relative 'schema'
require_relative 'search_engine/analysis'

module V1

  module SearchEngine

    ITEMS_JSON_FILE = File.expand_path("../../../spec/items.json", __FILE__)
    COLLECTIONS_JSON_FILE = File.expand_path("../../../spec/collections.json", __FILE__)

    def self.dataset_files
      [
       ITEMS_JSON_FILE,
       COLLECTIONS_JSON_FILE
      ]
    end

    def self.display_shard_status
      status = shard_status
      puts "Shard allocation for index: #{status['index']}"
      status['assigned'].sort_by {|k,v| k}.each do |node, list|
        puts "#{node}: #{list.join(', ')}"
      end

      status['shard_state'].keys.select {|s| s != 'STARTED'}.each do |state|
        puts "#{ state }: #{ status['shard_state'][state].join(', ') }"
      end
    end
    
    def self.shard_status
      res = HTTParty.get(Config.search_endpoint + '/_cluster/state').parsed_response
      
      nodes = res['nodes'].inject({}) {|memo,(code,body)| memo[code] = body['name']; memo}
      shards_by_nodes = nodes.inject({}) {|memo, (code,name)| memo[name] = [] ; memo}

      current = alias_to_index(Config.search_index)

      shard_state = {}
      res['routing_table']['indices'][current]['shards'].each do |shard_id, shardlist|
        shardlist.each do |status|
          shard = status['primary'] ? "#{status['shard']}" : "#{status['shard']}r"
          state = status['state']

          shard_state[ state ] ||= []
          shard_state[ state ] << shard
          if state != 'UNASSIGNED'
            shards_by_nodes[ nodes[ status['node'] ] ] << shard
          end
        end
      end

      { 'index' => current, 'assigned' => shards_by_nodes, 'shard_state' => shard_state }
    end

    def self.display_indices
      current = alias_to_index(Config.search_index)
      indices.map do |index|
        puts (index == current) ? "#{index}\t(DEPLOYED)" : index
      end      
    end

    def self.indices
      indices = HTTParty.get(Config.search_endpoint + '/_mapping')
        .parsed_response.keys
      indices.select {|index| index != '_river'}.sort
    end


    def self.doc_count
      url = Config.search_endpoint + '/' + Config.search_index + '/' + '_count'
      HTTParty.get(url).parsed_response['count'] rescue 'Error'
    end

    def self.schema_mapping
      timestamp = Time.now.to_s
      Schema.full_mapping.each do |res, fields|
        fields['_meta'] = { 'created' => timestamp }
      end
    end

    def self.service_status
      begin
        HTTParty.get(Config.search_endpoint).body
      rescue Exception => e
        "Error: #{e}"
      end
    end

    def self.find_alias(alias_name)
      all_indices = HTTParty.get(Config.search_endpoint + '/_aliases')
        .parsed_response
      all_indices.keys.select do |k|
        all_indices[k]['aliases'].key?(alias_name) rescue false
      end.first
    end

    def self.alias_to_index(alias_name)
      find_alias(alias_name)
    end

    def self.search_schema
      uri = Config.search_endpoint + '/' + alias_to_index(Config.search_index) + '/_mapping?pretty'
      begin
        HTTParty.get(uri).body
      rescue Exception => e
        "Error: #{e}"
      end
    end

  end

end
