require 'tire'
require 'v1/repository'
require 'active_support/core_ext'

module V1

  module Item
    # Specific fields that can be searched directly
    #TODO: Support collection-specific fields
    SEARCHABLE_FIELDS = %w( 
      q
      title
      description
      dplaContributor
      collection
      creator
      publisher
      created
      type
      format
      language
      subject
      rights
      spatial
      relation
      source
      contributor
      sourceRecord
    ).freeze

    # Exclusion list
    SEARCH_OPTION_FIELDS = %w( fields page_size offset )

    def self.search(params={})
      search = Tire::Search::Search.new(V1::Config::SEARCH_INDEX)
      queries = build_query_booleans(params) + build_temporal_query(params)
      
      #TODO: unrecognized field searches are currently returning the entire index.
      if queries.any?
        search.query do |query|
          queries.each {|q| query.boolean &q }
        end
      end

      if search.to_json == '{}'
        puts "********* WARNING ********* "
        puts "* Running a completely empty query. Probably not what you intended. *"
        puts "*************************** "
      end
      #puts "CURL: #{search.to_curl}"
      
      #search.results.each do |result|
      #  puts "### HIT (#{result['_id']}): #{result['_source']}"
      #end

      search.results
    end

    def self.build_query_strings(params)
      date_ranges_seen = []
      query_strings = []

      params.each do |field, value|
        next unless searchable_field?(field)

        if field == 'q'
          # free text search
          query_strings << value if !value.nil?
        elsif field =~ /^(.+)\.(before|after)$/
          # generic date field range search
          base_name = $1
          if !date_ranges_seen.include? base_name
            # remember base field name to avoid double-processing 
            date_ranges_seen << base_name
            query_strings << date_range_query_string(base_name, params)
          end            
        else
          # field search
          query_strings << "#{field}:#{value}"
        end
      end

      query_strings.flatten
    end
    def self.build_query_booleans(params)
      queries = []
      build_query_strings(params).each do |query_string|
        queries << lambda do |boolean|
          boolean.must do |must|
            must.string query_string
          end
        end
      end
      queries
    end

    def self.date_range_query_string(base_name, params)
      # Inclusive range queries: square brackets. Exclusive range queries: curly brackets.
      after = params["#{base_name}.after"].presence || '*'
      before = params["#{base_name}.before"].presence || '*'
      "#{base_name}:[#{after} TO #{before}]"
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

    def self.direct_range(hash={})
      #TODO: Remove (DEV only)
      search = Tire::Search::Search.new(V1::Config::SEARCH_INDEX)
      rangeq = ['temporal.end', { :gte => '1960' }]
      search.query do
        boolean do
          must { range(*rangeq) }
        end
      end
      puts "CURL: #{search.to_curl}"
      puts "Got: #{search.results.size}"

      search.results.each do |result|
        puts result.inspect
      end
    end

    def self.direct(str)
      #TODO: Remove (DEV only)
      search = Tire::Search::Search.new(V1::Config::SEARCH_INDEX)
      search.query do
          must { string "#{str}" }
      end
      puts "CURL: #{search.to_curl}"

      "Got: #{search.results.size}"
      search.results.each do |result|
        puts result.inspect
      end
    end

    def self.searchable_field?(field)
      # Note: Properly detects range searches on searchable fields
      SEARCHABLE_FIELDS.include?(field =~ /^(.+)\.(before|after)$/ ? $1 : field)
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
#puts V1::Item.direct_range({}).first
