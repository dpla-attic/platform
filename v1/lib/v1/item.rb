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
      temporal
      relation
      source
      contributor
      sourceRecord
    ).freeze

    # Exclusion list
    SEARCH_OPTION_FIELDS = %w( fields page_size offset )

    def self.date_range_query_string(base_name, params)
      # Inclusive range queries: square brackets. Exclusive range queries: curly brackets.
      min = params["#{base_name}.start"].presence || '*'
      max = params["#{base_name}.end"].presence || '*'
      "#{base_name}:[#{min} TO #{max}]"
    end

    def self.searchable_field?(field)
      SEARCHABLE_FIELDS.include?(field =~ /^(.+)\.(start|end)$/ ? $1 : field)
    end

    def self.build_query_strings(params)
      date_ranges_seen = []
      query_strings = []

      params.each do |field, value|
        next unless searchable_field?(field)
        query_string = nil

        # if it has .start or .end, look for matching inverse, process as date range (and remember it's handled)
        # date ranges can be $field.start and/or $field.end
        if field =~ /^(.+)\.(start|end)$/
          # date range search
          base_name = $1
          if !date_ranges_seen.include? base_name
            # remember base field name to avoid double-processing 
            date_ranges_seen << base_name
            query_string = date_range_query_string(base_name, params)
          end            
        elsif field == 'q'
          # free text search
          query_string = value
        else
          # field search
          query_string = "#{field}:#{value}"
        end

        #TODO: handle empty field, empty value or otherwise-bad search?
        query_strings << query_string if !query_string.nil?
      end

      query_strings
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

    def self.search(params={})
      search = Tire::Search::Search.new(V1::Config::SEARCH_INDEX)
      queries = build_query_booleans(params)

      if queries.any?
        search.query do |query|
          queries.each {|q| query.boolean &q }
        end
      end

      #puts "#CURL: #{search.to_curl}"
      #"Got: #{search.results.size}"
      search.results
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
