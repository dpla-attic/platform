require 'v1/config'
require 'v1/schema'
require 'json'
require 'tire'

module V1

  module StandardDataset

    INPUT_FILE = "../standard_dataset/items.json"

    def self.source_item_count
      items_file = File.expand_path(INPUT_FILE, __FILE__)
      items = JSON.load( File.read(items_file) )
      items.size
    end

    def self.indexed_item_count(results)
      result = JSON.load(results.body)
      failures = result['items'].select {|item| !item['index']['error'].nil? }
      result['items'].size - failures.size
    end

    def self.recreate_index!
      # Delete and create the index
      #TODO: add production env check

      items = process_input_file(INPUT_FILE)

      import_result = nil
      Tire.index(V1::Config::SEARCH_INDEX) do
        delete
        create V1::Schema::ELASTICSEARCH_MAPPING
        import_result = import items
        refresh
      end

      if source_item_count != indexed_item_count(import_result)
        raise "FAILED to import all items"
      end

      return display_import_result(import_result)
    end

    def self.display_import_result(import_result)
      result = JSON.load(import_result.body)
      failures = result['items'].select {|item| !item['index']['error'].nil? }
      result_count = result['items'].size
      puts "Imported #{result_count - failures.size}/#{result_count} items OK"

      if failures.any?
        puts "\nERROR: The following items failed to import correctly:"
        failures.each do |item|
          puts "#{ item['index']['_id'] }: #{ item['index']['error'] }"
        end
      end
      return result['items']
    end

    def self.process_input_file(json_file)
      # Load and pre-process items from the json file
      items_file = File.expand_path(json_file, __FILE__)
      items = JSON.load( File.read(items_file) )
      puts "Loaded #{items.size} items from source JSON file"

      items.each {|item| item['_type'] = "item"}
    end

    def self.recreate_river!
      repository_uri = URI.parse(V1::Config.get_repository_endpoint)

      river_payload = {
        type: "couchdb",
        couchdb: {
          host: repository_uri.host,
          port: repository_uri.port,
          db: V1::Config::REPOSITORY_DATABASE,
          user: V1::Config.get_repository_read_only_username,
          password: V1::Config.get_repository_read_only_password,
          filter: nil
        },
        index: {
          index: V1::Config::SEARCH_INDEX,
          type: 'item'
        }
      }

      Tire::Configuration.url(V1::Config.get_search_endpoint)
      delete_river!
      create_result = Tire::Configuration.client.put(
                                                  "#{Tire::Configuration.url}/_river/items/_meta",
                                                  river_payload.to_json
                                                  )
      puts "River create: #{create_result.inspect}"
      refresh_result = Tire.index('_river').refresh
      puts "River refresh: #{refresh_result.inspect}"
    end

    def self.delete_river!
      Tire::Configuration.client.delete("#{V1::Config.get_search_endpoint}/_river/items")
    end
  end

end
