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

    # Maximum facets to return. See use case details
    MAXIMUM_FACETS_COUNT = 'not implemented'

    # General query params that are not type-specific
    BASE_QUERY_PARAMS = %w( q controller action sort_by sort_by_pin sort_order page page_size facets fields callback ).freeze
    
    def validate_params(params)
      # Raises exception if any unrecognized search params are present. Query-based 
      # extensions (e.g: spatial.distance) are added here as well. Does not examine
      # contents of fields containing field names, such as sorting, facets, etc.
      invalid = params.keys - (BASE_QUERY_PARAMS + V1::Schema.queryable_fields)
      if invalid.any?
        raise BadRequestSearchError, "Invalid field(s) specified in query: #{invalid.join(',')}"
      end
    end

    def search(params={})
      validate_params(params)
      search = Tire.search(V1::Config::SEARCH_INDEX) do |search|
        got_queries = true if V1::Searchable::Query.build_all(search, params)
        got_queries = true if V1::Searchable::Filter.build_all(search, params)
        got_queries = true if V1::Searchable::Facet.build_all(search, params, !got_queries)

        sort_attrs = build_sort_attributes(params)
        search.sort { by(*sort_attrs) } if sort_attrs

        #TODO: size 0 if facets and no query (use q='' to force a global search)
        search.from search_offset(params)
        search.size search_page_size(params)
    
        field_params = validate_field_params(params)
        search.fields(field_params) if field_params
        
        # for testability, this block should always return its search object
        search
      end

      begin
        #verbose_debug(search)
        #puts "CURL: #{search.to_curl}"
        return wrap_results(search)
      rescue Tire::Search::SearchRequestFailed => e
        error = JSON.parse(search.response.body)['error'] rescue nil
        raise InternalServerSearchError, error
      end
    end

    def build_sort_attributes(params)
      #TODO allow a csv list of sort params
      sort_by_name = params['sort_by'].to_s
      return nil if sort_by_name == ""

      # Validate sort_by
      sort_by = V1::Schema.flapping('item', sort_by_name)
      if sort_by.nil?
        raise BadRequestSearchError, "Invalid field(s) specified in sort_by parameter: #{sort_by_name}"
      end
      if sort_by.analyzed?
        raise BadRequestSearchError, "Non-sortable field(s) specified in sort_by parameter: #{sort_by_name}"
      end

      # Validate sort_order
      order = params['sort_order'].to_s.downcase
      if !( %w(asc desc).include?(order) )
        order = DEFAULT_SORT_ORDER 
      end

      # Special handling for geo_point sorts
      if sort_by.type == 'geo_point'
        if params['sort_by_pin'].to_s == ''
          raise BadRequestSearchError, "Missing required sort_by_pin parameter when sorting on #{sort_by.name}"
        end
        ['_geo_distance', { sort_by.name => params['sort_by_pin'], 'order' => order }]
      else
        [sort_by.name, order]
      end
    end

    def wrap_results(search)
      results = search.results
      {
        'count' => results.total,
        'start' => search.options[:from],
        'limit' => search.options[:size],
        'docs' => format_results(results),
        'facets' => format_facets(results.facets)
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

    def format_facets(facets)
      return [] unless facets
      facets.each do |name, payload|
        if payload['_type'] == 'date_histogram' &&
            name =~ /(.+)\.(.*)$/ &&
            V1::Searchable::Facet::DATE_INTERVALS.include?($2)
          payload['entries'].each do |value_hash|
            value_hash['time'] = format_date_facet($2, value_hash['time'])
          end
        end
      end
    end

    def format_date_facet(interval, value)
      formats = {
        'day' => '%F',
        'month' => '%Y-%m',
        'year' => '%Y',
        'decade' => '%Y',
        'century' => '%C00'
      }      

      # just return their value if we can't format it
      return value unless formats[interval]
      
      date = Time.at(value/1000).to_date
      final = date.strftime(formats[interval])
      
      # round decades down (E.g. 1993 -> 1990)
      (interval == 'decade' ? ((final.to_i * 0.1).floor * 10) : final).to_s
    end

    def validate_field_params(params)
      return nil unless params['fields'].present?
      fields = params['fields'].split(/,\s*/)
      
      invalid = fields - V1::Schema.queryable_fields
      if invalid.any?  
        raise BadRequestSearchError, "Invalid field(s) specified for fields parameter: #{invalid.join(',')}" 
      end
      
      fields
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
      #TODO: construct big "a OR b OR c" query to get all items in one trip to ES
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
      if search.to_json == '{}'
        puts "********* WARNING ********* "
        puts "* Running a completely empty query. Probably not what you intended. *"
        puts "*************************** "
      end
      #puts "JSON: #{search.to_json}"
      puts "CURL: #{search.to_curl}"
      # search.results.each do |result|
      #   puts "### HIT (#{result['_id']}): #{result.pretty_inspect}"
      # end
    end

    def direct(params={})
      s = Tire.search(V1::Config::SEARCH_INDEX) do
        query do
          boolean do
            must { string 'perplexed' }
          end
        end
      end
      verbose_debug(s)
      s.results
    end
    
  end

end
