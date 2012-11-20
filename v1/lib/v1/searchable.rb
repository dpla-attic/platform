require 'v1/repository'
require 'v1/schema'
require 'v1/searchable/query'
require 'v1/searchable/filter'
require 'v1/searchable/facet'
require 'tire'
#require 'active_support/core_ext'

module V1

  module Searchable

    # Default pagination size for search results
    DEFAULT_PAGE_SIZE = 10

    # Maximum facets to return. See use case details
    MAXIMUM_FACETS_COUNT = 'not implemented'

    # Default sort order for search results
    DEFAULT_SORT_ORDER = 'asc'

    def search(params={})
      searcher = Tire.search(V1::Config::SEARCH_INDEX) do |search|
        got_queries = V1::Searchable::Query.build_all(search, params)

        #intentional empty search: search.query { all }

        if params['facets'].present?
          # if there were no queries, return global facets. else; not global
          V1::Searchable::Facet.build_all(search, :facets => params['facets'], :global => got_queries)
        end
          
        spatial_query = V1::Searchable::Filter.spatial_coordinates_filter(params)
        search.filter(*spatial_query) if spatial_query

        sort_attrs = build_sort_attributes(params)
        search.sort { by(*sort_attrs) } if sort_attrs
        
        #canned example to sort by geo_point, unverified
        # sort do
        #   by :_geo_distance, 'addresses.location' => [lng, lat], :unit => 'mi'
        # end
        
        # handle pagination
        search.from get_search_starting_point(params)
        search.size get_search_size(params)

        # fields(['title', 'description'])
        
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
      #BARRETT: should just use search.results instead of json parsing, etc.
      response = JSON.parse(search.response.body) #.to_json
      Rails.logger.info search.response.body.as_json      

      docs = reformat_result_documents(response["hits"]["hits"])

      { 
        'count' => response["hits"]["total"],
        'start' => search.options[:from],
        'limit' => search.options[:size],
        'docs' => docs,
        'facets' => response['facets']
      }
    end

    def reformat_result_documents(docs)
      docs.map { |doc| doc['_source'].merge!({'score' => doc['_score']}) } 
    end

    def get_search_starting_point(params)
      page = params["page"]
      return 0 if page.nil? || page.to_i == 0
      get_search_size(params) * (page.to_i - 1)
    end
 
    def get_search_size(params)
      size = params["page_size"]
      return DEFAULT_PAGE_SIZE if size.nil? || size.to_i == 0
      size.to_i
    end

    def fetch(id)
      V1::Repository.fetch(id)
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
