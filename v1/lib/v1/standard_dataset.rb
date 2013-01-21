require 'v1/config'
require 'v1/repository'
require 'v1/schema'
require 'tire'

module V1

  module StandardDataset

    # NOTE: References to "items" in JSON returned by ElasticSearch are un-related to
    # the "item" resource DPLA defines. It's just a coincidence that the names are the same.
    
    SEARCH_RIVER_NAME = 'dpla_river'
    ITEMS_JSON_FILE = File.expand_path("../../../spec/items.json", __FILE__)

    def self.recreate_env!
      recreate_index!
      import_test_dataset
      recreate_river!
    end

    def self.doc_count
      # Quick hack intended for rake tasks
      url = V1::Config.search_endpoint + '/' + V1::Config::SEARCH_INDEX + '/' + '_status'
      json = JSON.load( %x( curl #{url} ) )
      json['indices'][V1::Config::SEARCH_INDEX]['docs']['num_docs'] rescue 'ERROR'
    end

    def self.process_input_file(resource=nil, json_file)
      # Load and pre-process docs from the json file
      begin        
        docs = JSON.load( File.read(json_file) )
        if resource
          docs.each {|item| item['_type'] = resource}
        end
        return docs
      rescue JSON::ParserError => e
        # Try to output roughly 1 test doc so they can see the error.
        raise "JSON parse error: #{e.to_s.split(/\n/).first(25).join("\n")} \n[SNIP]..."
      end
    end

    def self.import_test_dataset
      import_data_file('item', ITEMS_JSON_FILE)
    end

    def self.import_data_file(resource, file)
      # imports a single file into ES
      import_result = nil
      input_json = process_input_file(resource, file)

      Tire.index(V1::Config::SEARCH_INDEX) do |tire|
        import_result = tire.import(input_json)
        tire.refresh
      end

      return display_import_result(import_result)
    end

    def self.recreate_index!
      # Delete and create the search index
      #TODO: add production env check
      endpoint_config_check

      Tire.index(V1::Config::SEARCH_INDEX) do |tire|
        tire.delete
        tire.create V1::Schema::ELASTICSEARCH_MAPPING
      end
    end

    def self.endpoint_config_check
      # Catch any calls that skipped the Tire initializer (perhaps from being run outside of Rails)
      if Tire::Configuration.url != V1::Config.search_endpoint
        raise "It doesn't look like Tire has been initalized to use the correct search endpoint"
      end
    end

    def self.display_import_result(import_result)
      result = JSON.load(import_result.body)
      failures = result['items'].select {|item| !item['index']['error'].nil? }
      result_count = result['items'].size

      if failures.any?
        puts "Imported #{result_count - failures.size}/#{result_count} docs OK"
        puts "\nERROR: The following docs failed to import correctly:"
        failures.each do |item|
          puts "#{ item['index']['_id'] }: #{ item['index']['error'] }"
        end
      end
      return result['items']
    end

    def self.recreate_river!
      endpoint_config_check
      delete_river!
      # pause long enough to let ElasticSearch actually shut the river down
      sleep 3
      create_river
    end

    def self.create_river
      endpoint_config_check

      repository_uri = URI.parse(V1::Repository.endpoint)
      # TODO: to copy couchdb field into different ES field via the river:
      # (under the couchdb section):     "script" : "ctx.doc._type = ctx.doc.dplaTypeField"
      # We may have to ref this for deletes:
      # https://github.com/wotifgroup/elasticsearch-river-couchdb/commit/325cb69963e42e252dcfc596c766ab4f12538428
      # and https://github.com/elasticsearch/elasticsearch-river-couchdb/issues/7
      river_payload = {
        type: "couchdb",
        couchdb: {
          host: repository_uri.host,
          port: repository_uri.port,
          db: V1::Config::REPOSITORY_DATABASE,
          user: V1::Config.dpla['read_only_user']['username'],
          password: V1::Config.dpla['read_only_user']['password'],
          filter: nil
        },
        index: {
          index: V1::Config::SEARCH_INDEX,
          type: 'item'
        }
      }

      response = Tire::Configuration.client.put(
                                                "#{Tire::Configuration.url}/_river/#{SEARCH_RIVER_NAME}/_meta",
                                                river_payload.to_json
                                                )

      create_result = JSON.parse(response.body)
      if create_result['ok']
        puts "River created OK"
      else
        puts "Problem creating river: #{create_result.inspect}"
      end
    end

    def self.delete_river!
      response = Tire::Configuration.client.delete("#{V1::Config.search_endpoint}/_river/#{SEARCH_RIVER_NAME}")
      #delete_result = JSON.parse(response.body)
      #puts "ERROR: #{ delete_result['error'] }" if response.code != 200
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
        'title' => timestamp
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
        puts "Actul title:    #{search_doc['title']}"
      else
        print "SUCCESS: Changes in test doc propogated by the River OK "
        puts "('title' => '#{search_doc['title']}' for id: #{test_doc_id})"
      end

      if !import_result.nil?
        # remove test doc from couch
        delete_doc = {'_id' => import_result['id'], '_rev' => import_result['rev']}
        V1::Repository.delete_docs([delete_doc])
      end
    end

  end

end
