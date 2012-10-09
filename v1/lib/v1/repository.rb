require 'v1/standard_dataset'
require 'json'
require 'couchrest'

module V1

  module Repository

    def self.fetch(id)
      db = CouchRest.database(endpoint)
      db.get(id.to_s)
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

      items = process_input_file("../standard_dataset/item.json")
      db.bulk_save items
    end

    def self.process_input_file(json_file)
      items_file = File.expand_path(json_file, __FILE__)
      JSON.load( File.read(items_file) )
    end

  end

end
