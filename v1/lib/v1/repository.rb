require 'v1/standard_dataset'
require 'json'
require 'couchrest'
require 'httparty'

module V1

  module Repository

    def self.fetch(id_list)
      # Accepts an array of ids or a string containing a comma separated list of ids
      id_list = id_list.split(/,\s*/) if id_list.is_a?(String)
      wrap_results(do_fetch(id_list))
    end

    def self.do_fetch(id_list)
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
      # BUG: This will throw a NoMethodError if results is all couch '404' responses
      results.map {|result| result['doc'].delete_if {|k,v| k =~ /^(_rev|_type)/} }
    end

    def self.recreate_env!
      recreate_database!
      #TODO: make recreate_database! also recreate_river, like V1::StandardDataset.recreate_search_index does
      import_test_dataset
      puts "CouchDB docs/views: #{ doc_count }"
      V1::StandardDataset.recreate_river!
    end

    def self.service_status(raise_exceptions=false)
      uri = endpoint + '/' + repository_database
      config = V1::Config.dpla['read_only_user']

      auth = {}
      if config && config['username']
        auth = {:basic_auth => {:username => config['username'], :password => config['password']}}
      end        

      begin
        HTTParty.get(uri, auth).body
      rescue Exception => e
        # let caller request exceptions or let it default to returning an informative string
        raise e if raise_exceptions
        "ERROR: #{e}"
      end
    end

    def self.doc_count
      # Intended for rake tasks
      #TODO: don't count views. In a cruel twist of fate, we may need a view to do that. :O
      CouchRest.database(admin_endpoint_database).info['doc_count'] rescue 'ERROR'
    end

    def self.import_test_dataset
      # Imports all the test data files
      import_data_file(V1::StandardDataset::ITEMS_JSON_FILE)
      import_data_file(V1::StandardDataset::COLLECTIONS_JSON_FILE)
    end

    def self.import_data_file(file)
      import_docs(V1::StandardDataset.process_input_file(file, false))
    end

    def self.import_docs(docs)
      db = CouchRest.database(admin_endpoint_database)
      begin
        db.bulk_save docs
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "ERROR: #{error['reason'] || e.to_s}"
      end
    end

    def self.delete_docs(docs)
      db = CouchRest.database(admin_endpoint_database)
      begin
        docs.each {|doc| db.delete_doc doc }
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "ERROR: #{error['reason'] || e.to_s}"
      end
    end

    def self.recreate_database!
      # Delete, recreate and repopulate the database
      #TODO: add production env check
      CouchRest.database(admin_endpoint_database).delete! rescue nil

      # create new db
      CouchRest.database!(admin_endpoint_database)

      recreate_users
    end

    def self.recreate_users
      #TODO: should we be creating the admin user here too? perhaps only if it does not exist?
      username = V1::Config.dpla['read_only_user']['username']
      password = V1::Config.dpla['read_only_user']['password'] 
      recreate_user(username, password)
      assign_roles
    end

    def self.recreate_user(username, password)
      users_db = CouchRest.database("#{admin_endpoint}/_users")
      couch_username = "org.couchdb.user:#{username}"
      
      # delete user if it exists
      user = users_db.get(couch_username) rescue nil
      users_db.delete_doc(user) if user

      user_doc = {
        '_id' => couch_username,
        'type' => 'user',
        'name' => username,
        'password' => password,
        'roles' => %w( reader )
      }
      result = users_db.save_doc(user_doc)
      raise "ERROR: #{result}" unless result['ok']
    end

    def self.assign_roles
      # Only creates new docs if they do not already exist
      db = CouchRest.database(admin_endpoint_database)      
      current_security = db.get( '_security' ) rescue nil
      if current_security.nil?
        security_doc = {
          '_id' => '_security',
          'admins' => {'roles' => %w( admin )},
          'readers' => {'roles' => %w( reader )}
        }
        roles_result = db.save_doc(security_doc)
        raise "ERROR: #{roles_result}" unless roles_result['ok']
      end        

      current_auth = db.get( '_design/auth' ) rescue nil
      if current_auth.nil?
        auth_doc = {
          '_id' => '_design/auth',
          'language' => 'javascript',
          'validate_doc_update' => "function(newDoc, oldDoc, userCtx) { if (userCtx.roles.indexOf('_admin') != -1) { return; } else { throw({forbidden: 'Only admins may edit the database'}); } }"
        }
        auth_result = db.save_doc(auth_doc)
        raise "ERROR: #{auth_result}" unless auth_result['ok']
      end
    end

    def self.read_only_endpoint
      config = V1::Config.dpla['read_only_user']
      "http://#{config['username']}:#{config['password']}@#{host}/#{repository_database}" 
    end

    def self.repository_database
      V1::Config::REPOSITORY_DATABASE
    end

    def self.admin_endpoint
      V1::Config.dpla['repository']['admin_endpoint'] rescue 'http://127.0.0.1:5984'
    end

    def self.admin_endpoint_database
      "#{admin_endpoint}/#{repository_database}"
    end

    def self.host
      V1::Config.dpla['repository']['host'] rescue '127.0.0.1:5984'
    end
    
    def self.endpoint
      "http://#{host}"
    end

  end

end
