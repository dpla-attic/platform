require 'v1/schema'
require 'v1/repository'
require 'tire'
require 'active_support/core_ext'

module V1

  module Item

    # Default spatial.distance "range" value
    DEFAULT_SPATIAL_DISTANCE = '20mi'.freeze

    # Default pagination size for search results
    DEFAULT_PAGE_SIZE = 10.freeze

    # Exclusion list
    SEARCH_OPTION_FIELDS = %w( fields page_size offset ).freeze

    def self.build_spatial_coordinates_query(params)
      #TODO: validate spatial.distance units?
      return nil unless params['spatial.coordinates'].present?
      
      coordinates = params['spatial.coordinates']
      distance = params['spatial.distance'].presence || DEFAULT_SPATIAL_DISTANCE

      ['geo_distance', 'spatial.coordinates' => coordinates, 'distance' => distance]
    end

    def self.build_all_queries(params)
      [
        build_field_queries(params),
        build_temporal_query(params)
      ].flatten
    end

    def self.direct(params={})
      s = Tire.search(V1::Config::SEARCH_INDEX) do
        query do
          boolean do
            must { string 'description:perplexed' }
          end
        end
      end
      verbose_debug(s)
      s.results
    end

    def self.search(params={})
      queries = build_all_queries(params)

      searcher = Tire.search(V1::Config::SEARCH_INDEX) do |search|

        if queries.any?
          search.query do |query|
            queries.each {|q| query.boolean &q }
          end
        end

        spatial_query = build_spatial_coordinates_query(params)
        search.filter(*spatial_query) if spatial_query

        #sort_attrs = [:title, 'desc']
        #sort { by *sort_attrs }
        #canned example to sort by geo_point, unverified
        # sort do
        #   by :_geo_distance, 'addresses.location' => [lng, lat], :unit => 'mi'
        # end
        #paginate

        # for testability, this block should always return its search object
        search
      end

      #verbose_debug(searcher)
      searcher.results
    end

    def self.verbose_debug(search)
      if search.to_json == '{}'
        puts "********* WARNING ********* "
        puts "* Running a completely empty query. Probably not what you intended. *"
        puts "*************************** "
      end
      puts "CURL: #{search.to_curl}"

      search.results.each do |result|
        puts "### HIT (#{result['_id']}): #{result.inspect}"
      end
    end

    def self.build_field_query_strings(params)
      seen_date_ranges = []
      query_strings = []
      params.each do |field, value|
        next if value.blank?

        if field == 'q'
          query_strings << value
        elsif field =~ /^(created)\.(before|after)$/
          if !seen_date_ranges.include? $1
            query_strings << build_date_range_queries($1, params)
            # remember field so we don't doubledip it with the other end of the range
            seen_date_ranges << $1
          end
        else
          mapping = V1::Schema.item_mapping(field)
          next if mapping.nil? #skip unrecognized fields, including spatial.distance
          # temporal.after and created.after won't have a mapping, and are handled elsewhere
          
          if field =~ /(.+)\.(.+)/
            next if mapping[:type] == 'geo_point'  #build geo search elsewhere
            next if $2 =~ /^(before|after)$/  #build range elsewhere
            query_strings << "#{field}:#{value}"
          else
            query_strings << (mapping[:properties] ? "#{field}.\\*:#{value}" : "#{field}:#{value}")
          end
        end
      end

      query_strings
    end
    
    def self.build_date_range_queries(field, params)
      if params.keys.include?("#{field}.before") || params.keys.include?("#{field}.after")
        after = params["#{field}.after"].presence || '*'
        before = params["#{field}.before"].presence || '*'
        # Inclusive range queries: square brackets. Exclusive range queries: curly brackets.
        "#{field}:[#{after} TO #{before}]"
      end
    end

    def self.build_field_queries(params)
      queries = []
      build_field_query_strings(params).each do |query_string|
        queries << lambda do |boolean|
          boolean.must do |must|
            must.string query_string
          end
        end
      end
      queries
    end

    def self.build_temporal_ranges(params)
      ranges = []
      if params['temporal.after']
        limits = { :gte => params['temporal.after'] }
        # uncomment the below to enforce a strict "between" query rather than the
        # the default "if there is any overlap in timeframes" we use now.
        #limits[:lte] = params['temporal.before'] if params['temporal.before']
        ranges << ['temporal.end', limits]
      end
      if params['temporal.before']
        limits = { :lte => params['temporal.before'] }
        # see above "between" comment
        #limits[:gte] = params['temporal.after'] if params['temporal.after']
        ranges << ['temporal.start', limits]
      end
      ranges
    end

    def self.build_temporal_query(params)
      build_temporal_ranges(params).inject([]) do |memo, range|
        memo << lambda do |boolean|
          boolean.must do |must|
            must.range(*range)
          end
        end
        memo
      end
    end

    def self.fetch(id)
      # viva la delegation
      V1::Repository.fetch(id)
    end

  end

end

#NOTE: should we post process all results with result.to_hash.except(:_type, :_index, :_version, etc) ?
#puts V1::Item.search({'title' => 'banana'}).first
#puts V1::Item.search({'created.start' => '2012-01-07'}).first
#puts V1::Item.search({'created.start' => '1950', 'created.end' => '1980'}).first
#puts V1::Item.search({'created.end' => '1980'}).first
#puts V1::Item.direct_coordinates().first

#V1::Item.search({ 'spatial.distance' => '100mi', 'spatial.coordinates' => '42.1,-71' })
