require 'v1/search_error'
require 'v1/repository'
require 'v1/schema'
require 'v1/searchable/query'
require 'v1/searchable/filter'
require 'v1/searchable/facet'
require 'tire'
require 'active_support/core_ext'

module V1

  module Searchable

    # Default pagination size for search results
    DEFAULT_PAGE_SIZE = 10

    # Default max page size
    DEFAULT_MAX_PAGE_SIZE = 100
    
    # Default sort order for search results
    DEFAULT_SORT_ORDER = 'asc'

    # General query params that are not type-specific
    BASE_QUERY_PARAMS = %w( q controller action sort_by sort_by_pin sort_order page page_size facets facet_size fields callback ).freeze
    
    def validate_query_params(params)
      # Raises exception if any unrecognized search params are present. Query-based 
      # extensions (e.g: spatial.distance) are added here as well. Does not examine
      # contents of fields containing field names, such as sorting, facets, etc.
      invalid = params.keys - (BASE_QUERY_PARAMS + V1::Schema.queryable_fields)
      if invalid.any?
        raise BadRequestSearchError, "Invalid field(s) specified in query: #{invalid.join(',')}"
      end
    end

    def search(params={})
      validate_query_params(params)
      validate_field_params(params)

      #, :search_type => 'count' (on an empty search) would just return total count
      # params['title'] = 'peanut'
      # params['fields'] = 'id,subject.name,scriptfield'
      search = Tire.search(V1::Config::SEARCH_INDEX) do |search|
        queries_ran = []
        queries_ran << V1::Searchable::Query.build_all(search, params)
        queries_ran << V1::Searchable::Filter.build_all(search, params)
        V1::Searchable::Facet.build_all(search, params, !queries_ran.any?)
        
        sort_attrs = build_sort_attributes(params)
        search.sort { by(*sort_attrs) } if sort_attrs

        search.from search_offset(params)
        search.size search_page_size(params)

        search.fields(params['fields'].to_s.split(/,\s*/)) if params['fields'].present?
        
        # for testability, this block should always return its search object
        search
      end

      begin
        #verbose_debug(search)
        puts "CURL: #{search.to_curl}" if search.respond_to? :to_curl
        #puts "JSON: #{search.to_json}" if search.respond_to? :to_json
        return wrap_results(search, params)
      rescue Tire::Search::SearchRequestFailed => e
        error = JSON.parse(search.response.body)['error'] rescue nil
        raise InternalServerSearchError, error
      end
    end

    def build_sort_attributes(params)
      #TODO: can also sort by multiple fields: sort { by [{'published_on' => 'desc'}, {'_score' => 'asc'}] } 

      sort_by_name = params['sort_by'].to_s
      return nil if sort_by_name == ""

      # Validate sort_order
      order = params['sort_order'].to_s.downcase
      if !( %w(asc desc).include?(order) )
        order = DEFAULT_SORT_ORDER 
      end

      # Validate sort_by
      sort_by = V1::Schema.flapping('item', sort_by_name)
      if sort_by.nil?
        raise BadRequestSearchError, "Invalid field(s) specified in sort_by parameter: #{sort_by_name}"
      end

      if !sort_by.sortable?
        raise BadRequestSearchError, "Non-sortable field(s) specified in sort_by parameter: #{sort_by_name}"
      end

      if sort_by.sort == 'field'
        [ {sort_by.name => order} ]
      elsif sort_by.sort == 'script'
        [{
           '_script' => {
             'script' => "s='';foreach(val : doc['#{sort_by.name}'].values) {s += val + ' '} s",
             'type' => "string",
             'order' => order
           }
         }]
      elsif sort_by.sort == 'geo_distance'
        if params['sort_by_pin'].to_s == ''
          raise BadRequestSearchError, "Missing required sort_by_pin parameter when sorting on #{sort_by.name}"
        end
        [ {'_geo_distance' => { sort_by.name => params['sort_by_pin'], 'order' => order } } ]
      end
    end

    def wrap_results(search, params)
      results = search.results
      facet_size = V1::Searchable::Facet.facet_size(params)
      
      {
        'count' => results.total,
        'start' => search.options[:from],
        'limit' => search.options[:size],
        'docs' => format_results(results),
        'facets' => format_facets(results.facets, facet_size)
      }
    end

    def format_results(results)
      results.map do |doc|
        if doc['_source'].present?
          doc['_source'].delete_if {|k,v| k =~ /^_type/}
          doc['_source'].merge!({'score' => doc['_score']})
        else
          doc['fields'] || {}
        end
      end
    end

    def format_facets(facets, facet_size)
      return [] unless facets

      facet_keys = {
        'date_histogram' => 'entries',
        'terms' => 'terms',
        'geo_distance' => 'ranges'
      }

      facets.each do |name, payload|
        type = payload['_type']

        if facet_size
          payload[facet_keys[type]] = payload[facet_keys[type]].first(facet_size.to_i)
        end

        if type == 'date_histogram'
          # TODO: We probably need to be stricter about what is definitely a field and
          # what is probably an interval here.
          name =~ /(.+)\.(.*)$/
          payload['entries'].each do |value_hash|
            value_hash['time'] = format_date_facet(value_hash['time'], $2)
          end
        end
      end
    end

    def format_date_facet(value, interval=nil)
      # Value is from ElasticSearch and it is in UTC milliseconds since the epoch
      formats = {
        'day' => '%F',
        'month' => '%Y-%m',
        'year' => '%Y',
        'decade' => '%Y',
        'century' => '%C00'
      }      

      # Default to 'day' format (e.g. '1993-01-31')
      format = formats[interval] || '%F'

      # temporary hack to work around ElasticSearch adjusting timezones and breaking our dates
      offset = 5 * 60 * 60 * 1000 #5 hours in milliseconds
      # offset *= -1 if value < 0  #TODO: subtract for pre-epoch dates, add for post-epoch
      #      Rails.logger.debug "offset/value: #{offset} / #{value}"
      date = Time.at( (value+offset)/1000 ).to_date
      final = date.strftime(format)
      
      # round decades down (E.g. 1993 -> 1990)
      (interval == 'decade' ? ((final.to_i * 0.1).floor * 10) : final).to_s
    end

    def validate_field_params(params)
      invalid = params['fields'].to_s.split(/,\s*/) - V1::Schema.queryable_fields
      if invalid.any?  
        raise BadRequestSearchError, "Invalid field(s) specified for fields parameter: #{invalid.join(',')}" 
      end
    end
    
    def search_offset(params)
      page = params["page"].to_i
      page == 0 ? 0 : search_page_size(params) * (page - 1)
    end

    def search_page_size(params)
      size = params["page_size"].to_i
      if size == 0
        DEFAULT_PAGE_SIZE
      elsif size > DEFAULT_MAX_PAGE_SIZE
        DEFAULT_MAX_PAGE_SIZE
      else
        size
      end
    end

    def fetch(ids)
      # Transparently translate "id" values from query to the "_id" values CouchDB expects
      doc_ids = []
      missing_ids = []
      #TODO: use search.ids() method, or add logic for it in search()
      ids.each do |id|
        result = search({'id' => id})
        
        if result["count"] == 1
          #Save the doc's '_id' if search returned a single 'id' match
          doc_ids << result["docs"].first["_id"]
        elsif result["count"] == 0
          #Save the 'id' as missing if search did not find the doc 
          missing_ids << id 
        end
      end

      if doc_ids.empty? && ids.count == 1
        raise NotFoundSearchError, "Document not found"
      end

      results = V1::Repository.fetch(doc_ids)
      #TODO: what if search finds an ID, but the fetch does not find that ID
 
      if missing_ids.any?
        results['docs'].concat( missing_ids.map { |id| { 'id' => id, 'error' => '404'} } )
      end
      #TODO: Make sure we only return public IDs in this results set (for missing or found docs)
      results
    end

    def verbose_debug(search)
      #puts "JSON: #{search.to_json}"
      puts "CURL: #{search.to_curl}"
    end

  end

end
