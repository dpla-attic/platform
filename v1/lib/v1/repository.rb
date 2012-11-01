require 'v1/standard_dataset'
require 'json'
require 'couchrest'

module V1

  module Repository
    # Accepts an array of id strings ["A,"1","item1"], a single string id "1"
    # Or a comma separated string of ids "1,2,3"
    def self.fetch(id_list)
      db = CouchRest.database(endpoint)
      id_list = id_list.split(',') if id_list.is_a?(String)
      db.get_bulk(id_list)["rows"] 
    end

    def self.endpoint
      @endpoint_uri ||= V1::Config.get_repository_endpoint + '/' + V1::Config::REPOSITORY_DATABASE
    end

    def self.recreate_database!
      # Delete and create the database
      #TODO: add production env check

      # delete it if it exists
      CouchRest.database(endpoint).delete! rescue RestClient::ResourceNotFound

      # create a new one
      db = CouchRest.database!(endpoint)
      V1::StandardDataset.recreate_river!

      items = process_input_file("../standard_dataset/items.json")
      db.bulk_save items
    end

    def self.process_input_file(json_file)
      items_file = File.expand_path(json_file, __FILE__)
      JSON.load( File.read(items_file) )
    end

  end

end
