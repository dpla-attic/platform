require 'v1/config'
require 'v1/repository'
require 'v1/schema'
require 'tire'

module V1

  module StandardDataset

    SEARCH_RIVER_NAME = 'dpla_river'
    ITEMS_JSON_FILE = File.expand_path("../../../spec/items.json", __FILE__)
    COLLECTIONS_JSON_FILE = File.expand_path("../../../spec/collections.json", __FILE__)

    def self.dataset_files
      [
       ITEMS_JSON_FILE,
       COLLECTIONS_JSON_FILE
      ]
    end

    def self.recreate_env!
      recreate_index!
      import_test_dataset
      puts "ElasticSearch docs: #{ doc_count }"
    end

    def self.doc_count
      url = V1::Config.search_endpoint + '/' + V1::Config::SEARCH_INDEX + '/' + '_status'
      HTTParty.get(url)['indices'][V1::Config::SEARCH_INDEX]['docs']['num_docs'] rescue 'Error'
    end

    def self.process_input_file(json_file, inject_type)
      # Load and pre-process docs from the json file
      begin        
        docs = JSON.load( File.read(json_file) )
        docs.map {|doc| doc['_type'] = doc['ingestType']} if inject_type
        return docs
      rescue JSON::ParserError => e
        # Try to output roughly 1 test doc so they can see the error.
        raise JSON::ParserError, "JSON parse error: #{e.to_s.split(/\n/).first(25).join("\n")} \n[SNIP]..."
      end
    end

    def self.import_test_dataset
      dataset_files.each {|file| import_data_file file}
    end

    def self.import_data_file(file)
      import_result = nil
      Tire.index(V1::Config::SEARCH_INDEX) do |tire|
        import_result = tire.import(process_input_file(file, true))
        tire.refresh
      end

      return display_import_result(import_result)
    end

    def self.recreate_index!
      # Delete and create the search index
      #TODO: add production env check
      endpoint_config_check

      # Delete the river here to avoid it tripping all over itself and getting
      # confused when we create it later
      delete_river!
      sleep 1

      # inject the timestamp because it's nice to see in the search_schema rake task
      timestamp = Time.now.to_s
      dated_mapping = V1::Schema::ELASTICSEARCH_MAPPING.dup.each do |res,fields|
        fields['_meta'] = { 'created' => timestamp }
      end

      Tire.index(V1::Config::SEARCH_INDEX) do |tire|
        tire.delete

        tire.create( { 'mappings' => dated_mapping } )
        if tire.response.code != 200
          raise "Error: #{ JSON.parse(tire.response.body)['error'] }" 
        end
      end

      #TODO: add optional arg to this method to control creating the river here
      create_river
    end

    def self.endpoint_config_check
      # Catch any calls that skipped the Tire initializer (perhaps from being run outside of Rails)
      if Tire::Configuration.url != V1::Config.search_endpoint
        raise "It doesn't look like Tire has been initalized to use the correct search endpoint"
      end
    end

    def self.display_import_result(import_result)
      # NOTE: References to 'items' in this method are un-related to the "item" resource
      # that DPLA defines. It's just a coincidence that the names are the same.

      result = JSON.load(import_result.body)
      failures = result['items'].select {|item| !item['index']['error'].nil? }

      if failures.any?
        result_count = result['items'].size
        puts "Imported #{result_count - failures.size}/#{result_count} docs OK"
        puts "\nError: The following docs failed to import correctly:"
        failures.each do |item|
          puts "#{ item['index']['_id'] }: #{ item['index']['error'] }"
        end
      end
      return result['items']
    end

    def self.recreate_river!
      # Pause after a successful delete to give ElasticSearch a chance to actually 
      # shut down and delete the existing river.
      sleep 3 if delete_river!.code == 200

      create_river
    end

    def self.create_river
      # To delete a doc: https://github.com/elasticsearch/elasticsearch-river-couchdb/issues/7
      repo_uri = URI.parse('http://' + V1::Repository.reader_cluster_database)

      river_payload = {
        'type' => 'couchdb',
        'couchdb' => {
          'host' => repo_uri.host,
          'port' => repo_uri.port,
          'db' => repo_uri.path.sub('/', ''),
          'user' => repo_uri.user,
          'password' => repo_uri.password,
          'script' => "ctx._type = ctx.doc.ingestType || 'unknown'"
        },
        'index' => {
          'index' => V1::Config::SEARCH_INDEX
        }
      }

      response = Tire::Configuration.client.put(
                                                "#{river_endpoint}/_meta",
                                                river_payload.to_json
                                                )

      create_result = JSON.parse(response.body)

      if response.code == 200 || response.code == 201
        # Sleep a bit to let creation process finish on elasticsearch server
        sleep 1
        
        # Verify that the river was actually created successfully. ElasticSearch's initial response
        # in $create_result won't report if there was a deeper problem with the river we tried to
        # create. (This has happened before, due to the use of the script field.)
        real_status = JSON.parse(river_status)
        if real_status['_source'] && real_status['_source']['error']
          node = real_status['_source']['node']['name']
          error = real_status['_source']['error']
          raise "Error creating river on node '#{node}': #{error}"
        else
          puts "River created OK"
        end
      else
        raise "Problem creating river: #{create_result.inspect}"
      end
    end

    def self.delete_river!
      Tire::Configuration.client.delete(river_endpoint)
    end

    def self.river_status
      begin
        HTTParty.get("#{river_endpoint}/_status").body
      rescue Exception => e
        "Error: #{e}"
      end
    end

    def self.river_endpoint
      "#{V1::Config.search_endpoint}/_river/#{SEARCH_RIVER_NAME}"
    end

    def self.service_status
      begin
        HTTParty.get(V1::Config.search_endpoint).body
      rescue Exception => e
        "Error: #{e}"
      end
    end

    def self.search_schema(resource=nil)
      uri = V1::Config.search_endpoint + '/' + V1::Config::SEARCH_INDEX
      uri += "/#{resource}" if resource
      uri += '/_mapping?pretty'
      begin
        HTTParty.get(uri).body
      rescue Exception => e
        "Error: #{e}"
      end
    end

    def self.test_river
      # End to end test integration to verify that changes are making it from the
      # repository to the search index via the River properly. It is driven by a rake
      # task (rather than an integration test) because it is safe to run in production.
      endpoint_config_check

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
      import_result = V1::Repository.import_docs([doc]).first

      if !import_result['ok']
        # it already exist, so we need to update it
        # fetch doc from couchdb to get latst _rev
        update_result = V1::Repository.do_fetch([test_doc_id]).first

        # update doc with required _rev info and new title
        doc = update_result['doc'].merge('title' => doc['title'])
        import_result = V1::Repository.import_docs([doc]).first
      end

      # add a delay to give time for ES to get the change notification from the River
      # If CouchDB is doing any significant amount of heavy lifting when this is run,
      # this delay will probably not be long enough, and this test will appear to fail.
      # Repeating the test a few seconds later then most likely succeed.
      sleep 5

      search_doc = V1::Item.fetch( [doc['id']] )['docs'].first rescue nil

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
        V1::Repository.delete_docs([delete_doc])
      end
    end

  end

end
