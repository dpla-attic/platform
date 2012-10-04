module V1

  module Couchdb

    def self.recreate_database!
      # Delete and create the database
      #TODO: add production env check

      items = process_input_file("../standard_dataset/item.json")
      db_uri = V1::Config.get_repository_endpoint + '/dpla'

      # delete it if it exists
      CouchRest.database(db_uri).delete! rescue RestClient::ResourceNotFound

      # create a new one
      db = CouchRest.database!(db_uri)
      db.bulk_save items
      #items.map {|doc| db.save_doc doc}
    end


    def self.process_input_file(json_file)
      items_file = File.expand_path(json_file, __FILE__)
      JSON.load( File.read(items_file) )
    end


  end

end
