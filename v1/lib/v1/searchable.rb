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
    BASE_QUERY_PARAMS = %w( q controller action sort_by sort_order page page_size facets fields callback ).freeze
    
    def validate_params(params)
      # Raises exception if any unrecognized search params are present. Extensions made
      # to the mapping for query reasons (e.g: spatial.distance) are added here as well.
      #TODO: Make the mapped_fields call type-specific to avoid overlaps between fields/subfields
      # with the same name across multiple types
      invalid_fields = params.keys - (BASE_QUERY_PARAMS + V1::Schema.mapped_fields)
      if invalid_fields.any?
        raise BadRequestSearchError, "Invalid field(s) specified in query: #{invalid_fields.join(',')}"
      end
    end

    def search(params={})
      validate_params(params)
      searcher = Tire.search(V1::Config::SEARCH_INDEX) do |search|
        #intentional empty search: search.query { all }
        got_queries = true if V1::Searchable::Query.build_all(search, params)
        got_queries = true if V1::Searchable::Filter.build_all(search, params)
        got_queries = true if V1::Searchable::Facet.build_all(search, params['facets'], !got_queries)
        #TODO: for symmetry's sake, make Facet.build_all take params like the others

        sort_attrs = build_sort_attributes(params)
        search.sort { by(*sort_attrs) } if sort_attrs
        
        #canned example to sort by geo_point, unverified
        # sort do
        #   by :_geo_distance, 'addresses.location' => [lng, lat], :unit => 'mi'
        # end
        
        # handle pagination
        search.from get_search_starting_point(params)
        search.size get_search_size(params)
    
        # limit fields in results
        field_params = parse_field_params(params)
        search.fields field_params if field_params
        
        # for testability, this block should always return its search object
        search
      end

      #verbose_debug(searcher)
      return build_dictionary_wrapper(searcher)
    end

    def build_sort_attributes(params)
      #TODO big picture check on field being available 
      return nil unless params['sort_by'].present?
 
      order = params['sort_order']
      if !( order.present? && %w(asc desc).include?(order.downcase) )
        order = DEFAULT_SORT_ORDER 
      end

      [params['sort_by'], order]
    end

    def build_dictionary_wrapper(search)
      results = search.results #response
      docs = reformat_result_documents(results)

      { 
        'count' => results.total,
        'start' => search.options[:from],
        'limit' => search.options[:size],
        'docs' => docs,
        'facets' => results.facets
      }
    end

    def reformat_result_documents(docs)
      docs.map do  |doc|
        if doc['_source'].present?
          doc['_source'].merge!({'score' => doc['_score']})
        else
          doc['fields']
        end
      end
    end

    def parse_field_params(params)
      return nil unless params['fields'].present?
      fields = params['fields'].split(',')
      
      #Check if all fields are valid
      invalid_fields = fields - V1::Schema.mapped_fields
      if invalid_fields.any?  
        invalids = invalid_fields.join(',')
        raise BadRequestSearchError, "Invalid field(s) specified for 'fields' parameter: #{invalids}" 
      end
      
      fields
    end
    
    def get_search_starting_point(params)
      page = params["page"].to_i
      page == 0 ? 0 : get_search_size(params) * (page - 1)
    end

    def get_search_size(params)
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
      doc_ids = []
      missing_ids = []
      ids.each do |id|
        result = search({'id' => "#{id}"})
        #Save the doc's '_id' if search returned a single 'id' match
        doc_ids << result["docs"].first["_id"] if result["count"] == 1
        #Save the 'id' as missing if search did not find the doc 
        missing_ids << id if result["count"] == 0
      end

      if doc_ids.empty? && ids.count == 1
        raise NotFoundSearchError, "Document not found"
      end

      results = V1::Repository.fetch(doc_ids)
 
      if missing_ids.any?
        error_records = missing_ids.map { |id| { 'id' => id, 'error' => '404'} }
        return results.concat(error_records)
      end

      results
    end

    def verbose_debug(search)
      if search.to_json == '{}'
        puts "********* WARNING ********* "
        puts "* Running a completely empty query. Probably not what you intended. *"
        puts "*************************** "
      end
      puts "CURL: #{search.to_curl}"
      puts "JSON: #{search.to_json}"

      search.results.each do |result|
        puts "### HIT (#{result['_id']}): #{result.inspect}"
      end
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
