require 'v1/standard_dataset'
require 'json'
require 'couchrest'

module V1

  module Repository

    # Accepts an array of id strings ["A,"1","item1"], a single string id "1"
    # Or a comma separated string of ids "1,2,3"
    def self.fetch(id_list)
      db = CouchRest.database(read_only_endpoint)
      id_list = id_list.split(',') if id_list.is_a?(String)
      db.get_bulk(id_list)["rows"] 
    end

    def self.read_only_endpoint
      config = V1::Config.dpla['couch_read_only']
      read_only_login = "#{config['username']}:#{config['password']}"
      "http://#{read_only_login}@#{host}/#{repository_database}" 
    end

    def self.repository_database
      V1::Config::REPOSITORY_DATABASE
    end

    def self.admin_endpoint
      config = V1::Config.dpla['couch_admin']
      config['endpoint'] 
    end

    def self.recreate_database!
      # Delete, recreate and repopulate the database
      #TODO: add production env check

      items = process_input_file(V1::StandardDataset::ITEMS_JSON_FILE)
      repo_database = admin_endpoint + "/#{repository_database}"
      # delete it if it exists
      CouchRest.database(repo_database).delete! rescue RestClient::ResourceNotFound

      # create a new one
      db = CouchRest.database!(repo_database)

      # create read only user and lock down security
      create_read_only_user
      lock_down_repository_roles

      V1::StandardDataset.recreate_river!

      db.bulk_save items
    end

    def self.create_read_only_user
      username = V1::Config.dpla['couch_read_only']['username']
      password = V1::Config.dpla['couch_read_only']['password'] 

      # delete read only user if it exists
      users_db = CouchRest.database("#{admin_endpoint}/_users")
      read_only_user = users_db.get("org.couchdb.user:#{username}") rescue RestClient::ResourceNotFound
      users_db.delete_doc(read_only_user) if read_only_user.is_a? CouchRest::Document

      user_hash = {
        :type => "user",
        :name => username,
        :password => password,
        :roles => ["reader"]
      }

      RestClient.put(
        "#{admin_endpoint}/_users/org.couchdb.user:#{username}",
        user_hash.to_json,
        {:content_type => :json, :accept => :json}
      )
    end

    def self.lock_down_repository_roles
      security_hash = {
        :admins => {"roles" => ["admin"]},
        :readers => {"roles"  => ["admin","reader"]}
      }
      RestClient.put(
        "#{admin_endpoint}/#{repository_database}/_security",
        security_hash.to_json
      )

      # add validation to ensure only admin can create new docs
      design_doc_hash = {
        :_id => "_design/auth",
        :language => "javascript",
        :validate_doc_update => "function(newDoc, oldDoc, userCtx) { if (userCtx.roles.indexOf('_admin') !== -1) { return; } else { throw({forbidden: 'Only admins may edit the database'}); } }"
      }
      RestClient.put(
        "#{admin_endpoint}/#{repository_database}/_design/auth",
        design_doc_hash.to_json
      )
    end

    def self.process_input_file(json_file)
      items_file = File.expand_path(json_file, __FILE__)
      JSON.load( File.read(items_file) )
    end
    
    def self.host
      #TODO: test
      config = V1::Config.get_repository_config
      if config.nil?
        host = '127.0.0.1'
        port = '5984'
      else
        host = config['httpd']['bind_address']
        port = config['httpd']['port']
      end
      "#{host}:#{port}"
    end

    def self.endpoint
      "http://#{host}"
    end


  end

end
