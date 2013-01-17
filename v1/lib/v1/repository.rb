require 'v1/standard_dataset'
require 'json'
require 'couchrest'

module V1

  module Repository

    def self.fetch(id_list)
      # Accepts an array of id strings ["A,"1","item1"], a single string id "1"
      # Or a comma separated string of ids "1,2,3"
      id_list = id_list.split(/,\s*/) if id_list.is_a?(String)
      wrap_results(do_fetch(id_list))
    end

    def self.do_fetch(id_list)
      #TODO: update tests
      db = CouchRest.database(read_only_endpoint)
      db.get_bulk(id_list)["rows"]
    end

    def self.wrap_results(results)
      { 
        'count' => results.size,
        'docs' => reformat_results(results)
      }
    end

    def self.reformat_results(results)
      results.map {|result| result['doc'].delete_if {|k,v| k =~ /^(_rev|_type)/} }
    end

    def self.read_only_endpoint
      config = V1::Config.dpla['read_only_user']
      read_only_login = "#{config['username']}:#{config['password']}"
      "http://#{read_only_login}@#{host}/#{repository_database}" 
    end

    def self.repository_database
      V1::Config::REPOSITORY_DATABASE
    end

    def self.admin_endpoint
      V1::Config.dpla['repository']['admin_endpoint'] 
    end

    def self.admin_endpoint_database
      "#{admin_endpoint}/#{repository_database}"
    end

    def self.recreate_env!
      recreate_database!
      import_test_dataset
      puts "CouchDB docs/views: #{ doc_count }"
      V1::StandardDataset.recreate_river!
    end

    def self.doc_count
      # Intended for rake tasks
      #TODO: don't count views. In a cruel twist of fate, we may need a view
      # to do that. :O
      json = JSON.load( %x( curl #{admin_endpoint_database} ) )
      json['doc_count'] rescue 'ERROR'
    end

    def self.import_test_dataset
      # Imports all the test data files
      import_data_file( V1::StandardDataset::ITEMS_JSON_FILE )
    end

    def self.import_data_file(file)
      import_docs( V1::StandardDataset.process_input_file(nil, file) )
    end

    def self.import_docs(docs)
      db = CouchRest.database(admin_endpoint_database)
      begin
        db.bulk_save docs
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "FATAL ERROR: #{error['reason'] || e.to_s}"
      end
    end

    def self.delete_docs(docs)
      db = CouchRest.database(admin_endpoint_database)
      begin
        docs.each {|doc| db.delete_doc doc }
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "FATAL ERROR: #{error['reason'] || e.to_s}"
      end
    end

    def self.recreate_database!
      # Delete, recreate and repopulate the database
      #TODO: add production env check
      CouchRest.database(admin_endpoint_database).delete! rescue RestClient::ResourceNotFound

      # create new db
      CouchRest.database!(admin_endpoint_database)

      create_read_only_user
      lock_down_repository_roles
    end

    def self.create_read_only_user
      username = V1::Config.dpla['read_only_user']['username']
      password = V1::Config.dpla['read_only_user']['password'] 

      # delete read only user if it exists
      users_db = CouchRest.database("#{admin_endpoint}/_users")
      read_only_user = users_db.get("org.couchdb.user:#{username}") rescue RestClient::ResourceNotFound
      if read_only_user.is_a?(CouchRest::Document)
        users_db.delete_doc(read_only_user)
      end

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
      #TODO: why do readers have the admin role here?
      security_hash = {
        :admins => {"roles" => %w( admin )},
        :readers => {"roles" => %w( admin reader )}
      }
      RestClient.put(
        "#{admin_endpoint_database}/_security",
        security_hash.to_json
      )

      # add validation to ensure only admin can create new docs
      design_doc_hash = {
        :_id => "_design/auth",
        :language => "javascript",
        :validate_doc_update => "function(newDoc, oldDoc, userCtx) { if (userCtx.roles.indexOf('_admin') !== -1) { return; } else { throw({forbidden: 'Only admins may edit the database'}); } }"
      }
      RestClient.put(
        "#{admin_endpoint_database}/_design/auth",
        design_doc_hash.to_json
      )
    end

    def self.host
      config = V1::Config.dpla['repository']
      # return value from config or CouchDB default
      (config && config['host']) ? config['host'] : "127.0.0.1:5984"
    end
    
    def self.endpoint
      "http://#{host}"
    end

  end

end
