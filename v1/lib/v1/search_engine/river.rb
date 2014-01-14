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
        return if HTTParty.head(endpoint(name)).code == 404

        puts "Deleting river '#{name}'"
        result = HTTParty.delete(endpoint(name))

        if result.success?
          # Give a successful river delete a chance to finish on the search server
          sleep 3
        else
          puts "INFO: Could not delete river '#{name}' because: #{result}"
        end

        result
      end

      def self.list_all
        url = Config.search_endpoint + '/_river/_mapping'
        rivers = HTTParty.get(url).parsed_response['_river'].keys rescue []
        rivers.map do |river|
          "#{river} -> index:#{ service_meta(river)['_source']['index']['index'] }"
        end
      end

      def self.validate_river_params_for(index)
        
        if index.nil?
          if SearchEngine.index_exists?(index)
            message = "is actually an index. It should always point to an alias."
          else
            message = "doesn't point to any index. Perhaps you forgot to deploy an index first."
          end
          raise "Error: Expected alias '#{Config.search_index}' #{message}"
        elsif SearchEngine.find_alias(index)
          # Don't create a river pointed at an alias
          raise "Refusing to create river pointed at an alias" 
        end
      end
      
      def self.create_river(options={})
        # defaults are the active index and river
        river = options['river'] || Config.river_name
        index = options['index'] || SearchEngine.alias_to_index(Config.search_index)

        # this fails if the index has not been deployed
        
        raise "Cannot create river for an index that does not exist" if index.nil?
        validate_river_params_for(index)

        #TODO: refuse to create a river that already exists #HTTParty.head ...
        repository = Repository.reader_cluster_database.to_s
        river_payload = river_creation_doc(index, repository).to_json

        # :body key must be a symbol
        result = HTTParty.put(
                              "#{endpoint(river)}/_meta",
                              :body => river_payload
                              )

        raise "Problem creating river: #{JSON.parse(result.body)}" unless result.success?
        
        # Sleep a bit to let creation process finish on elasticsearch server
        sleep 5
        puts verify_river_status(river)
      end
      
      def self.river_creation_doc(index, database_uri)
        # bulk_size and bulk_timeout are just safe guesses at good values for production
        # TODO: production could use larger values, but would then probably need
        # a longer delay for river_test, etc.
        repo_uri = URI.parse(database_uri)
        {
          'type' => 'couchdb',
          'couchdb' => {
            'host' => repo_uri.host,
            'port' => repo_uri.port,
            'db' => repo_uri.path.sub('/', ''),
            'user' => repo_uri.user,
            'password' => repo_uri.password,
            'bulk_size' => '500',
            'bulk_timeout' => '3s',
            'script' => river_script
          },
          'index' => {
            'index' => index
          }
        }
      end

      def self.river_script
        #Note: The null value assignment below works in conjunction with the schema's
        #null_value attribute to force empty/null values to sort last, ascending. (ES's
        #'missing' sort attr only works on numeric fields as of v0.20.6.)
        beginning = "ctx._type = ctx['doc']['ingestType'] || 'unknown';"
        middle = ""
        fields = [ "['sourceResource']['title']" ]
        fields.each do |field|
          middle += "
            if (ctx._type == 'item') {
              ctx['doc']['admin'] = ctx['doc']['admin'] || {};
              ctx['doc']['admin']['sourceResource'] = ctx['doc']['admin']['sourceResource'] || {};
              if (ctx['doc']['sourceResource']) {
                if (ctx['doc']#{field}) {
                  ctx['doc']['admin']#{field} = ctx['doc']#{field}[0].length > 1 ? ctx['doc']#{field}[0] : ctx['doc']#{field};
                } else {ctx['doc']['admin']#{field} = null;}
              }
            }
          "
        end
        beginning + middle
      end

      def self.service_status(river=river_name)
        begin
          HTTParty.get("#{endpoint(river)}/_status").parsed_response
        rescue Exception => e
          "Error: #{e}"
        end
      end

      def self.service_meta(river=river_name)
        begin
          HTTParty.get("#{endpoint(river)}/_meta").parsed_response
        rescue Exception => e
          "Error: #{e}"
        end
      end

      def self.river_name
        Config.river_name
      end
      
      def self.endpoint(name=river_name)
        Config.search_endpoint + '/_river/' + name
      end

      def self.verify_river_status(name=river_name)
        # Verify that the river was actually created successfully. ElasticSearch's initial
        # response in $create_result won't report if there was a deeper problem with the
        # river we tried to create.
        name ||= river_name
        status = service_status(name)

        raise "River '#{name}' does not exist" unless status['exists']
        source = status['_source']
        node = source['node']['name']

        if source && source['error']
          error = source['error']
          raise "Problem with river on node '#{node}': #{error}"
        else
          if last_sequence.nil?
            return "River exists but is not flowing (last_seq is nil)"
          else
            index = service_meta(name)['_source']['index']['index']
            return "River '#{name}' pointed at index '#{index}' running on node '#{node}'"
          end
        end
      end

      def self.last_sequence(name=river_name)
        # name will be present but nil when called from a rake task
        name ||= river_name
        response = HTTParty.get(endpoint(name) + '/_seq').parsed_response
        seq = response['_source']['couchdb']['last_seq'] rescue nil

        return nil if seq.nil?

        # handle bigcouch's last_seq format if it looks like it
        seq = JSON.parse(seq).first if seq !~ /^\d+$/

        seq.to_i
      end

      def self.current_velocity(name=river_name)
        # Sadly, a delta of 10 does not guarantee 10 docs have been processed, but this
        # is still a relatively useful metric. Zero velocity means "no activity at all."
        name ||= river_name
        sleep_time = 3

        start_seq = last_sequence(name)
        if start_seq.nil?
          raise "Can't get velocity for river '#{name}'. It looks broken. (last_seq is nil)"
        end
        sleep sleep_time
        end_seq = last_sequence(name)

        velocity = (end_seq.to_f - start_seq.to_f) / sleep_time
        "#{ sprintf("%.1f", velocity) } docs/sec"
      end

      def self.river_test
        # End to end test integration to verify that changes are making it from the
        # repository to the search index via the River properly. It is driven by a rake
        # task (rather than an integration test) because it is safe to run in production.
        SearchEngine.endpoint_config_check
        resource = Item.resource

        puts verify_river_status
        
        original_seq = last_sequence

        doc_id = "DPLARIVERTEST"
        test_doc = {
          '_id' => doc_id,
          'id' => doc_id,
          '@id' => Time.now,
          'ingestType' => resource
        }

        fetched_doc = Repository.raw_fetch([doc_id]).first

        if fetched_doc['doc']
          # update pre-existing doc with new @id
          test_doc = fetched_doc['doc'].merge('@id' => test_doc['@id'])
        end
        Repository.save_doc(test_doc)

        # sleep for a good bit to make sure river has time to index doc
        sleep 8
        new_seq = last_sequence

        if new_seq != original_seq
          puts "SUCCESS: River's last_seq value incremented after test doc was written to repository"
          search_doc = Item.fetch( [test_doc['id']] )['docs'].first rescue nil

          if search_doc.nil?
            puts "But... the test doc was not found in ElasticSearch yet, so the river is likely backlogged"
          end
        else
          puts "Fail: River's last_seq (#{original_seq || 'nil'}) has not changed since test doc was written to repository"
        end

        Repository.delete_docs([test_doc])
        sleep 3
        HTTParty.delete(Config.search_endpoint + '/' + Config.search_index + '/' + resource + '/' + doc_id)
      end
    
    end

  end

end

