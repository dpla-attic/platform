require 'v1/config'

module V1

  module StandardDataset

    def self.recreate_index!
      # Delete and create the index
      #TODO: add production env check

      items = process_input_file("../standard_dataset/item.json")

      Tire.index(V1::Config::SEARCH_INDEX) do
        delete

        # TODO: move to ES's config/default-mapping.json 
        create :mappings => {
          :item => {
            :properties => {
              #NOTE: No longer needed now that the source data uses _id, I think. -phunk
              #:id       => { :type => 'string' },  
              :title    => { :type => 'string' },
              :dplaContributor    => { :type => 'string' },
              :collection    => { :type => 'string' },
              :creator    => { :type => 'string' },
              :publisher   => { :type => 'string' },
              :created => { :type => 'date' },
              :type    => { :type => 'string' }, #image, text, etc
              :format    => { :type => 'string' }, #mime-type
              :language    => { :type => 'string' }, 
              :subject    => { :type => 'string' },
              :description    => { :type => 'string' },
              :rights    => { :type => 'string' },
              :spatial   => { :type => 'string' },
              :temporal    => { :type => 'string' },
              :relation    => { :type => 'string' },
              :source    => { :type => 'string' },
              :contributor    => { :type => 'string' },
              :sourceRecord    => { :type => 'string' }
            }
          }
        }

        import_result = import items
        #puts "import_result: #{import_result.body.to_json}"
        #TODO: eval as JSON and assert items.size == result size
        refresh
      end
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
