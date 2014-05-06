require_relative 'search_engine'
require 'couchrest'
require 'httparty'

module V1

  module Repository

    DEFAULT_API_AUTH_DATABASE = 'dpla_api_auth'
    DEFAULT_DASHBOARD_DATABASE = 'dashboard'
    
    def self.fetch(ids)
      # Accepts an array of ids or a string containing a comma separated list of ids
      ids = ids.split(/,\s*/) if ids.is_a?(String)
      wrap_results(raw_fetch(ids))
    end

    def self.raw_fetch(ids)
      reader_cluster_database.get_bulk(ids)["rows"]
    end

    def self.wrap_results(results)
      #TODO: We don't need to wrap this and send the size. let the consumer do that.
      found_results = format_results(results)
      { 
        'count' => found_results.size,
        'docs' => found_results,
      }
    end

    def self.format_results(results)
      results.map do |result|
        result['doc'].delete_if {|k,v| k =~ /^(_rev|_type)/} if result['doc']
      end
    end

    def self.recreate_doc_database
      # rake target
      recreate_database(admin_cluster_database)
    end
    
    def self.recreate_api_keys_database
      # rake target
      recreate_database(admin_cluster_auth_database)
    end
    
    def self.recreate_env(include_river=false)
      recreate_doc_database
      recreate_api_keys_database
      SearchEngine.recreate_river if include_river
      recreate_users
      import_test_api_keys
      create_api_auth_views
    end

    def self.recreate_env_with_docs(include_river=false)
      recreate_env(include_river)
      import_test_dataset
      puts "CouchDB docs/views: #{ doc_count }"
    end

    def self.doc_count
      # Intended for rake tasks
      admin_cluster_database.info['doc_count'] rescue 'Error'
    end

    def self.import_test_dataset
      SearchEngine::dataset_files.each {|file| import_data_file file}
    end

    def self.import_data_file(file)
      import_docs(SearchEngine.process_input_file(file, false))
    end

    def self.save_doc(doc)
      begin
        admin_cluster_database.save_doc doc
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "Error: #{error['reason'] || e.to_s}"
      end
    end
    

    def self.import_docs(docs)
      db = admin_cluster_database
      begin
        db.bulk_save docs
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise Exception, "Error: #{error['reason'] || e.to_s}"
      end
    end

    def self.delete_docs(docs)
      db = admin_cluster_database
      begin
        docs.each {|doc| db.delete_doc doc }
      rescue RestClient::BadRequest => e
        error = JSON.parse(e.response) rescue {}
        raise "Error: #{error['reason'] || e.to_s}"
      end
    end

    def self.recreate_auth_database(import_test_keys=false)
      # rake task entry point
      recreate_database(admin_cluster_auth_database)
      #recreate_auth_design_doc(db)
      import_test_api_keys if import_test_keys
    end

    def self.create_api_auth_views
      # TODO: move to a JSON file and import from there. Ditto for dpla DB utils
      # example: curl 'http://hz4:5950/dpla_api_auth/_design/api_auth_utils/_view/find_by_owner?key="aa44@dp.la"'
      db = admin_cluster_auth_database
      views_doc = {
        '_id' => "_design/api_auth_utils",
        :views => {
          :find_by_owner => {
            :map => "function(doc) {\n  if (doc.owner) {\n    emit(doc.owner, doc);\n  }\n}"
          }
        }
      }
      result = db.save_doc(views_doc)
      raise "Error: #{result}" unless result['ok']
    end

    def self.import_test_api_keys(owner=nil)
      # rake task entry point
      db = admin_cluster_auth_database
      keys = YAML.load_file(File.expand_path("../../../config/test_api_keys.yml", __FILE__))

      print "Test API keys: "
      print "ONLY FOR: #{owner}" if owner
      puts ""
      
      keys.each do |key, body|
        # Only import key for this owner
        next if owner && owner != body['owner']
        print "  #{ key }  #{body['owner']}  #{'(disabled)' if body['disabled'] === true}"

        begin
          result = db.save_doc( {'_id' => key}.merge(body) )
          puts ""
          puts "Error importing key: #{result}" unless result['ok']
        rescue RestClient::Conflict => e
          puts "  (key already present)"
        rescue => e
          raise "Error importing key: #{e}"
        end
      end
      #TODO: Needs _auth/design created
    end
    
    def self.recreate_database(db)
      # Delete and create a database
      #TODO: add production env check
      begin
        db.delete!
      rescue RestClient::ResourceNotFound
      rescue => e
        raise "DB Delete Error: #{e}"
      end

      begin
        db.create! && sleep(3)
      rescue StandardError => e
        raise "DB Create Error: #{e}"
      end
    end

    def self.recreate_users
      recreate_user
      db = admin_cluster_database
      #      assign_roles(db, true)  # these aren't used yet
      recreate_auth(db, force_recreate=false)
    end

    def self.recreate_user
      config = Config.dpla['repository']
      username = config['reader']['user'] rescue nil
      password = config['reader']['pass'] rescue nil

      raise "repository.reader.user attribute undefined" if username.nil?
      couch_username = "org.couchdb.user:#{username}"

      db = admin_node_users_database
      
      begin
        delete_results = db.delete_doc( db.get(couch_username) )
        raise "Delete pre-existing user '#{username}' error: #{delete_results}" unless delete_results['ok']
        # let the delete finish on the couchdb side
        sleep 1
      rescue RestClient::ResourceNotFound
      rescue => e
        raise "Unexpected error deleting user '#{username}': #{e}"
      end

      #TODO: Move this into its own method
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
        puts "Error: #{result}" unless result['ok']
      rescue => e
        raise "Create user error: #{e}"
      end
    end

    # def self.assign_roles(db, force_recreate=false)
    #   #TODO: verify need for this if we are not using database-admins yet
    #   # Only creates new docs if they do not already exist
    #   begin
    #     current_security = db.get('_security')
    #   rescue RestClient::ResourceNotFound
    #   end

    #   if current_security.nil? || force_recreate
    #     security_doc = {
    #       '_id' => '_security',
    #       'admins' => {'roles' => %w( admin )},
    #       'readers' => {'roles' => %w( reader )}
    #     }

    #     roles_result = db.save_doc(security_doc)
    #     # puts "Roles OK: #{roles_result.to_s}"
    #     raise "Error: #{roles_result}" unless roles_result['ok']
    #   end        
    # end
      
    def self.recreate_auth(db, force_recreate=false)
      current_auth = db.get( '_design/auth' ) rescue nil
      if current_auth.nil? || force_recreate
        auth_doc = {
          '_id' => '_design/auth',
          'language' => 'javascript',
          'validate_doc_update' => "function(newDoc, oldDoc, userCtx) { if (userCtx.roles.indexOf('_admin') != -1) { return; } else { throw({forbidden: 'Only admins may edit the database'}); } }"
        }
        
        auth_doc.merge!(current_auth) if current_auth
        auth_result = db.save_doc(auth_doc)
        raise "Error: #{auth_result} (current_auth is: #{current_auth})" unless auth_result['ok']
      end
    end
    
    def self.service_status(raise_exceptions=false)
      uri = URI.parse(reader_cluster_database.to_s)
      auth = {}

      if uri.user
        auth = {:basic_auth => {:username => uri.user, :password => uri.password}}
      end        

      begin
        HTTParty.get(uri.to_s, auth).body
      rescue Exception => e
        # let caller request exceptions or let it default to returning an informative string
        raise e if raise_exceptions
        "Error: #{e}"
      end
    end

    def self.repo_name
      Config.dpla['repository'].fetch('documents_database', Config::REPOSITORY_DATABASE)
    end

    def self.cluster_host
      # supplies default value if not defined in config file
      Config.dpla['repository'].fetch('cluster_host', node_host)
    end

    def self.node_host
      # supplies default value if not defined in config file
      Config.dpla['repository'].fetch('node_host', '127.0.0.1:5984')
    end

    def self.cluster_endpoint(role=nil, suffix='')
      build_endpoint(cluster_host, role, suffix)
    end

    def self.node_endpoint(role=nil, suffix='')
      build_endpoint(node_host, role, suffix)
    end

    def self.admin_node_users_database
      database(node_endpoint('admin', '/_users'))
    end

    def self.admin_cluster_auth_database
      name = Config.dpla['repository'].fetch('api_auth_database', DEFAULT_API_AUTH_DATABASE)
      database(cluster_endpoint('admin', name))
    end

    def self.admin_cluster_dashboard_database
      name = Config.dpla['repository'].fetch('dashboard_database', DEFAULT_DASHBOARD_DATABASE)
      database(cluster_endpoint('admin', name))
    end

    def self.admin_cluster_database
      database(cluster_endpoint('admin', repo_name))
    end

    def self.reader_cluster_database
      database(cluster_endpoint('reader', repo_name))
    end

    def self.database(url)
      CouchRest.database(url)
    end

    def self.build_endpoint(host, role=nil, suffix=nil)
      config = Config.dpla['repository']

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
