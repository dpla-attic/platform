module CukeApiHelper

  def compute_facet_counts(facets, query_string=nil)
    # Delicately massage query results facets structure into something more testable
    # This method has similar hash traversal logic as V1::Schema.field()
    # NOTE: Only matches ElasticSearch results for not_analyzed fields
    dataset = JSON.parse(load_dataset)
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
    #TODO: expect_success=false), false, really?
    resource_query(resource, params, true)['docs']
  end
  
  def resource_query(resource, params={}, expect_success=false)
    visit("/v2/#{resource}s?#{ params.to_param }")

    if expect_success && page.status_code != 200
      puts "Query expected HTTP 200 but got #{page.status_code} with params: #{params}"
      puts "page.source: #{page.source}"
      raise Exception 
    end

    JSON.parse(page.source) rescue nil
  end

  def resource_fetch(resource, ids)
    visit("/v2/#{resource}s/#{ ids }")
    
    if page.status_code != 200
      puts "Fetch query expected HTTP 200 but got #{page.status_code} for ids: #{ids}"
      puts "page.source: #{page.source}"
      raise Exception 
    end
    JSON.parse(page.source) rescue nil
  end

  ## /Collections additions/refactoring

  def item_fetch(ids)
    visit("/v2/items/#{ ids }")
    JSON.parse(page.source) rescue nil
  end

  def item_query_to_json(params={}, expect_success=false)
    item_query(params, true)['docs']
  end

  def item_query(params={}, expect_success=false)
    #    format = get_request_format(params)
    visit("/v2/items?#{ params.to_param }")

    if expect_success && page.status_code != 200
      puts "Query expected HTTP 200 but got #{page.status_code} with params: #{params}"
      puts "page.source: #{page.source}"
      raise Exception 
    end

    JSON.parse(page.source) rescue nil
  end

  # def get_request_format(params)
  #   format = params.delete 'format'
  #   format ? '.' + format : ''
  # end

  def load_dataset
    File.read(V1::StandardDataset::ITEMS_JSON_FILE)
  end

  def get_maintenance_file
    File.dirname(__FILE__) + "/../../tmp/maintenance.yml"
  end

  def create_maintenance_file
    system("touch #{get_maintenance_file}")
  end

  def remove_maintenance_file
    system("rm #{get_maintenance_file}")
  end

end

World(CukeApiHelper)
