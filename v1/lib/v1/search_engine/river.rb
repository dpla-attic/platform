require_relative '../config'
require_relative '../search_engine'
require_relative '../repository'
require 'tire'

module V1

  module SearchEngine

    module River

      def self.recreate_river
        delete_river
        create_river
      end

      def self.delete_river(name=river_name)
        return if HTTParty.head(river_endpoint(name) + '/_status').code == 404

        puts "Deleting river '#{name}'"
        result = HTTParty.delete(river_endpoint(name))

        if result.success?
          # Give a successful river delete a chance to finish on the search server
          sleep 3
        elsif result.code == 404
          #puts "INFO: Could not delete river '#{name}' because it doesn't exist. (Which is probably harmless.)"
        else
          puts "INFO: Could not delete river '#{name}' because: #{result}"
        end

        result
      end

      def self.create_river(options={})
        # defaults are the active index and river
        index = options['index'] || SearchEngine.alias_to_index(Config.search_index)
        river = options['river'] || Config.river_name

        result = HTTParty.put(
                              "#{river_endpoint(river)}/_meta",
                              :body => river_creation_doc(index).to_json
                              )

        raise "Problem creating river: #{JSON.parse(result.body)}" unless result.success?
        
        # Sleep a bit to let creation process finish on elasticsearch server
        sleep 1
        puts "Created river '#{river}' pointed at index '#{index}'" if verify_river_exists(river)
      end
      
      def self.river_creation_doc(index_name)
        repo_uri = URI.parse(Repository.reader_cluster_database.to_s)
        # bulk_size and bulk_timeout are just safe guesses at good values for production
        {
          'type' => 'couchdb',
          'couchdb' => {
            'host' => repo_uri.host,
            'port' => repo_uri.port,
            'db' => repo_uri.path.sub('/', ''),
            'user' => repo_uri.user,
            'password' => repo_uri.password,
            'bulk_size' => '100',
            'bulk_timeout' => '2s',
            'script' => "ctx._type = ctx.doc.ingestType || 'unknown'"
          },
          'index' => {
            'index' => index_name
          }
        }
      end

      def self.service_status(river=river_name)
        begin
          HTTParty.get("#{river_endpoint(river)}/_meta?pretty").body
        rescue Exception => e
          "Error: #{e}"
        end
      end

      def self.river_name
        V1::Config.river_name
      end
      
      def self.river_endpoint(name=river_name)
        Config.search_endpoint + '/_river/' + name
      end

      def self.verify_river_exists(river)
        # Verify that the river was actually created successfully. ElasticSearch's initial
        # response in $create_result won't report if there was a deeper problem with the
        # river we tried to create. 
        status = JSON.parse(service_status(river))

        if status['_source'] && status['_source']['error']
          node = status['_source']['node']['name']
          error = status['_source']['error']
          raise "Error creating river on node '#{node}': #{error}"
        else
          true
        end
      end
      
      def self.test_river
        # End to end test integration to verify that changes are making it from the
        # repository to the search index via the River properly. It is driven by a rake
        # task (rather than an integration test) because it is safe to run in production.
        SearchEngine.endpoint_config_check

        # get doc with id: DPLARIVERTEST from the test dataset
        test_doc_id = 'DPLARIVERTEST'
        timestamp = Time.now.to_s
        doc = {
          '_id' => test_doc_id,
          'id' => test_doc_id,
          'title' => timestamp,
          'ingestType' => 'item'  #any valid resource type
        }
        
        # post it to couchdb as a new doc
        import_result = Repository.import_docs([doc]).first

        if !import_result['ok']
          # it already exist, so we need to update it
          # fetch doc from couchdb to get latst _rev
          update_result = Repository.raw_fetch([test_doc_id]).first

          # update doc with required _rev info and new title
          doc = update_result['doc'].merge('title' => doc['title'])
          import_result = Repository.import_docs([doc]).first
        end

        # add a delay to give time for ES to get the change notification from the River
        # If CouchDB is doing any significant amount of heavy lifting when this is run,
        # this delay will probably not be long enough, and this test will appear to fail.
        # Repeating the test a few seconds later then most likely succeed.
        sleep 5

        search_doc = Item.fetch( [doc['id']] )['docs'].first rescue nil

        if search_doc.nil?
          puts "Fail: Test doc pushed to CouchDB but not found in ElasticSearch"
        elsif search_doc['title'] != timestamp
          puts "Fail: Test doc found in ElasticSearch, but was not updated correctly"
          puts "Expected title: #{timestamp}"
          puts "Actual title:   #{search_doc['title']}"
        else
          print "SUCCESS: Changes in test doc propogated by the River OK "
          puts "('title' => '#{search_doc['title']}' for id: #{test_doc_id})"
        end

        if !import_result.nil?
          # remove test doc from couch
          #TODO: Do an updelete here now that the river is type-specific
          delete_doc = {'_id' => import_result['id'], '_rev' => import_result['rev']}
          Repository.delete_docs([delete_doc])
        end

      end

    end

  end

end

