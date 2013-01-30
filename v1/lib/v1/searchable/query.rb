require 'v1/schema'
require 'active_support/core_ext'

module V1

  module Searchable

    module Query

      def self.build_all(search, params)
        # Returns boolean for "did we run any queries?"
        field_queries = field_queries(params)
        temporal_queries = temporal_queries(params)

        # Only call search.query.boolean if we have some queries to pass it.
        # Otherwise we'll get incorrect search results.
        return false if (field_queries.empty? && temporal_queries.empty?)

        search.query do |query|
          query.boolean do |boolean|

            field_queries.each do |query_string|
              boolean.must do |must|
                must.string *query_string
              end
            end

            temporal_queries.each do |temporal|
              boolean.must do |must|
                must.range *temporal
              end
            end

          end
        end
        true
      end

      def self.field_queries(params)
        # TODO: We need a parse_facet_name type method in here
        seen_date_ranges = []
        query_strings = []

        params.each do |name, value|
          next if value.blank?

          if name == 'q'
            query_strings << [value, 'fields' => ['_all']]
          elsif name =~ /^(created)\.(before|after)$/
            if !seen_date_ranges.include? $1
              query_strings << build_date_range_queries($1, params)
              # remember name so we don't doubledip it with the other end of the range
              seen_date_ranges << $1
            end
          else
            field = V1::Schema.flapping('item', name)
            next if field.nil?  #skip unmapped names, including spatial.distance
            # temporal.after and created.after won't have a mapping, and are handled elsewhere

            next if field.geo_point?  #build geo search elsewhere

            if name =~ /(.+)\.(.+)/
            # subfield search
              next if field.date? && $2 =~ /^(before|after)$/  #build date range elsewhere
              query_strings << [value, 'fields' => [field.name]]
            else
              # search in multiple fields
              fields_attr = field.subfields? ? "#{field.name}.*" : field.name
              query_strings << [value, 'fields' => [fields_attr]]
            end
          end
        end

        query_strings.map {|q| Array.wrap(q)}
      end
      
      def self.build_date_range_queries(field, params)
        if params.keys.include?("#{field}.before") || params.keys.include?("#{field}.after")
          after = params["#{field}.after"].presence || '*'
          before = params["#{field}.before"].presence || '*'
          # Inclusive range queries: square brackets. Exclusive range queries: curly brackets.
          ["[#{after} TO #{before}]", 'fields' => [field]]
        end
      end

      def self.temporal_queries(params)
        #TODO: test
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

    end

  end

end
