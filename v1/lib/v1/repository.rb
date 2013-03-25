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
      begin
        db = CouchRest.database(reader_cluster_database)
        return db.get_bulk(id_list)["rows"]
      rescue StandardError => e
        puts "do_fetch ERROR: #{e}"
      end
    end

    def self.wrap_results(results)
      { 
        'count' => results.size,
        'docs' => format_results(results)
      }
    end

    def self.format_results(results)
      results.map do |result|
        result['doc'].delete_if {|k,v| k =~ /^(_rev|_type)/} if result['doc']
      end
    end

    def self.recreate_env!
      recreate_database!
      #TODO: make recreate_database! also recreate_river, like V1::StandardDataset.recreate_search_index does
      import_test_dataset

      puts "CouchDB docs/views: #{ doc_count }"
      V1::StandardDataset.recreate_river!
    end

    def self.service_status(raise_exceptions=false)
      uri = URI.parse('http://' + reader_cluster_database)

      auth = {}
      if uri.user
        auth = {:basic_auth => {:username => uri.user, :password => uri.password}}
      end        

      begin
        HTTParty.get(uri.to_s, auth).body
      rescue Exception => e
        # let caller request exceptions or let it default to returning an informative string
        raise e if raise_exceptions
        "ERROR: #{e}"
      end
    end

    def self.doc_count
      # Intended for rake tasks
      #TODO: don't count views. In a cruel twist of fate, we may need a view to do that. :O
      CouchRest.database(admin_cluster_database).info['doc_count'] rescue 'ERROR'
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
      db = CouchRest.database(admin_cluster_database)
      begin
        db.bulk_save docs
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "ERROR: #{error['reason'] || e.to_s}"
      end
    end

    def self.delete_docs(docs)
      db = CouchRest.database(admin_cluster_database)
      begin
        docs.each {|doc| db.delete_doc doc }
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise "ERROR: #{error['reason'] || e.to_s}"
      end
    end

    def self.recreate_database!
      # Delete, recreate and repopulate the database
      #TODO: add production env check
      begin
        CouchRest.database(admin_cluster_database).delete!
      rescue RestClient::ResourceNotFound
      rescue => e
        raise "DB Delete Error: #{e}"
      end

      # create new db
      begin
        CouchRest.database!(admin_cluster_database)
      rescue StandardError => e
        raise "DB Create Error: #{e}"
      end

      #TODO: create a database admin (rather than use the system admin like we have been doing)
      recreate_users
    end

    def self.recreate_users
      recreate_user
      assign_roles(true)
    end

    def self.recreate_user
      config = V1::Config.dpla['repository']
      username = config['reader']['user'] rescue nil
      password = config['reader']['pass'] rescue nil

      raise "repository.reader.user attribute undefined" if username.nil?
      couch_username = "org.couchdb.user:#{username}"

      db = CouchRest.database( node_endpoint('admin', '/_users') )
      
      begin
        delete_results = db.delete_doc( db.get(couch_username) )
        raise "Delete pre-existing user '#{username}' error: #{delete_results}" unless delete_results['ok']
        # let the delete finish on the couchdb side
        sleep 1
      rescue RestClient::ResourceNotFound
      rescue => e
        raise "Unexpected error deleting user '#{username}': #{e}"
      end

      # generate salt and sha such that this is compatible with CouchDB 1.1.1+
      salt = SecureRandom.hex(16)
      password_sha = Digest::SHA1.hexdigest(password + salt)

      user_doc = {
        '_id' => couch_username,
        'type' => 'user',
        'name' => username,
        'salt' => salt,
        'password_sha' => password_sha,
        'roles' => %w( reader )
      }

      begin
        # puts "Saving user: #{username} with salt: #{salt} and SHA: #{password_sha}"
        result = db.save_doc(user_doc)
        puts "ERROR: #{result}" unless result['ok']
      rescue => e
        raise "Create user error: #{e}"
      end
    end

    def self.assign_roles(force_recreate=false)
      # Only creates new docs if they do not already exist
      db = CouchRest.database(admin_cluster_database)

      begin
        current_security = db.get('_security')
      rescue RestClient::ResourceNotFound
      end

      if current_security.nil? || force_recreate
        security_doc = {
          '_id' => '_security',
          'admins' => {'roles' => %w( admin )},
          'readers' => {'roles' => %w( reader )}
        }

        roles_result = db.save_doc(security_doc)
        # puts "Roles OK: #{roles_result.to_s}"
        raise "ERROR: #{roles_result}" unless roles_result['ok']
      end        

      current_auth = db.get( '_design/auth' ) rescue nil
      if current_auth.nil? || force_recreate
        auth_doc = {
          '_id' => '_design/auth',
          'language' => 'javascript',
          'validate_doc_update' => "function(newDoc, oldDoc, userCtx) { if (userCtx.roles.indexOf('_admin') != -1) { return; } else { throw({forbidden: 'Only admins may edit the database'}); } }"
        }
        auth_doc.merge!(current_auth) if current_auth
        auth_result = db.save_doc(auth_doc)
        # puts "Auth OK: #{auth_result.to_s}"
        raise "ERROR: #{auth_result}" unless auth_result['ok']
      end
    end
    
    def self.repo_name
      V1::Config::REPOSITORY_DATABASE
    end

    def self.cluster_host
      # supplies default value if not defined in config file
      V1::Config.dpla['repository'].fetch('cluster_host', node_host)
    end

    def self.node_host
      # supplies default value if not defined in config file
      V1::Config.dpla['repository'].fetch('node_host', '127.0.0.1:5984')
    end

    def self.cluster_endpoint(role=nil, suffix='')
      build_endpoint(cluster_host, role, suffix)
    end

    def self.node_endpoint(role=nil, suffix='')
      build_endpoint(node_host, role, suffix)
    end

    def self.admin_cluster_database
      cluster_endpoint('admin', repo_name)
    end

    def self.reader_cluster_database
      cluster_endpoint('reader', repo_name)
    end

    def self.build_endpoint(host, role=nil, suffix=nil)
      config = V1::Config.dpla['repository']

      auth_string = ''
      if role
        auth = config.fetch(role, {})
        auth_string = auth['user'].to_s + ':' + auth['pass'].to_s + '@' unless auth.empty?
      end

      if suffix
        suffix = (suffix =~ /^\// ? suffix : "/#{suffix}"  )
      else
        suffix = ''
      end
      
      auth_string + host + suffix
    end

  end

end
