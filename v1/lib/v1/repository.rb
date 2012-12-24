require 'v1/standard_dataset'
require 'json'
require 'couchrest'

module V1

  module Repository

    # Accepts an array of id strings ["A,"1","item1"], a single string id "1"
    # Or a comma separated string of ids "1,2,3"
    def self.fetch(id_list)
      db = CouchRest.database(read_only_endpoint)
      id_list = id_list.split(/,\s*/) if id_list.is_a?(String)
#      db.get_bulk(id_list)["rows"]
      wrap_results(db.get_bulk(id_list)["rows"])
    end

    def self.wrap_results(results)
      #TODO: JSONP link?
      { 
        'count' => results.size,
        'docs' => reformat_results(results)
      }
    end

    def self.reformat_results(results)
      results.map do |result|
        result['doc'].delete_if {|k,v| k =~ /^(_rev|_type)/}
      end
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

    def self.recreate_database!
      # Delete, recreate and repopulate the database
      #TODO: add production env check

      items = JSON.load( File.read(V1::StandardDataset::ITEMS_JSON_FILE) )

      repo_database = admin_endpoint + "/#{repository_database}"
      # delete it if it exists
      CouchRest.database(repo_database).delete! rescue RestClient::ResourceNotFound

      # create a new one
      db = CouchRest.database!(repo_database)

      create_read_only_user
      lock_down_repository_roles

      V1::StandardDataset.recreate_river!

      begin
        db.bulk_save items
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "FATAL ERROR: #{error['reason'] || e.to_s}"
      end
    end

    def self.create_read_only_user
      username = V1::Config.dpla['read_only_user']['username']
      password = V1::Config.dpla['read_only_user']['password'] 

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
      #TODO: why do readers have the admin role here?
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

    def self.host
      config = V1::Config.dpla['repository']
      if config.nil? || config['host'].nil?
        host = "127.0.0.1:5984" 
      else
        host = config['host'] 
      end
      host
    end
    
    def self.endpoint
      "http://#{host}"
    end

  end

end
