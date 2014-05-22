module CukeApiHelper

  def compute_facet_counts(facets, query_string=nil)
    # Delicately massage query results facets structure into something more testable
    # This method has similar hash traversal logic as V1::Schema.field()
    # NOTE: Only matches ElasticSearch results for not_analyzed fields
    dataset = load_dataset
    source = {}

    facets.each do |facet|
      field_names = facet.split('.')
      first_name = field_names.shift

      dataset.each do |doc|
        next unless doc.to_s =~ /#{query_string}/i
        next unless doc[first_name]  #we need to have the top level field at least
        
        source[facet] ||= {}
        current = doc[first_name]

        # traverse the doc hash, handling the common "hash containing a hash" case
        # as well as array values at the bottom level of the hash
        field_names.each do |word|
          next if current.nil?  #this doc doesnt have this subfield
          
          # get the values at this level of the doc hash
          if current.is_a? Hash
            current = current[word]
          elsif current.is_a? Array
            current = current.map {|c| c[word]}
          end
        end

        if current.is_a?(String)
          # count the value
          facet_value = current
          source[facet][facet_value] ||= 0
          source[facet][facet_value] += 1
        elsif current.is_a?(Array) && current.any?
          # count each value p
          current.each do |string|
            facet_value = string
            source[facet][facet_value] ||= 0
            source[facet][facet_value] += 1
          end
        end

      end
    end
    source
  end

  ## Collections additions/refactoring
  def resource_query_to_json(resource, params={}, expect_success=false)
    resource_query(resource, params, expect_success)['docs'] rescue nil #was (_, _, true)...
  end
  
  def resource_query(resource, params={}, expect_success=false)
    raise "Missing resource with params: #{params}" if resource.to_s == ''
    visit("/v2/#{resource}s?#{ params.to_param }")

    if expect_success && page.status_code != 200
      puts "Query expected HTTP 200 but got #{page.status_code} with params: #{params}"
      puts "page.source: #{page.source}"
      raise Exception 
    end

    JSON.parse(page.source) rescue nil
  end

  def json_ld_context_fetch(resource)
    visit("/v2/#{resource}s/context?api_key=#{@params['api_key']}")
  end

  def resource_fetch(resource, ids, expected_http_code=200)
    url = "/v2/#{resource}s/#{ids}?api_key=#{@params['api_key']}"
    url += "&#{@fields}" if @fields
    visit(url)
    
    expected_http_code = expected_http_code.to_i
    if page.status_code != expected_http_code
      puts "Fetch query expected HTTP #{expected_http_code} but got #{page.status_code} for ids: #{ids}"
      puts "page.source: #{page.source}"
      raise Exception 
    end
    JSON.parse(page.source) rescue nil
  end

  ## /Collections additions/refactoring

  def item_query_to_json(params={}, expect_success=false)
    resource_query('item', params, true)['docs']
  end

  def item_query(params={}, expect_success=false)
    resource_query('item', params, expect_success)
  end

  def load_dataset
    json = []
    V1::SearchEngine.dataset_files.each do |json_file|
      json.concat V1::SearchEngine.process_input_file(json_file, false)
    end
    json
  end

  def visit_status_endpoint(service)
    visit "/v2/status/#{service}"
  end

end

World(CukeApiHelper)
