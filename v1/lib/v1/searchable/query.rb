require 'v1/schema'
require 'active_support/core_ext'

module V1

  module Searchable

    module Query

      def self.build_all(search, params)
        # Returns boolean for "did we run any queries?"
        field_queries = field_queries(params)
        date_range_queries = date_range_queries(params)

        # Only call search.query.boolean if we have some queries to pass it.
        # Otherwise we'll get incorrect search results.
        return false if (field_queries.empty? && date_range_queries.empty?)

        search.query do |query|
          query.boolean do |boolean|

            field_queries.each do |query_string|
              boolean.must do |must|
                must.string *query_string
              end
            end

            date_range_queries.each do |temporal|
              boolean.must do |must|
                must.range *temporal
              end
            end

          end
        end
        true
      end


      def self.field_queriesORIG(params)
        # TODO: We need a parse_facet_name type method in here
        seen_date_ranges = []
        query_strings = []

        # We skip all query types that are handled elsewhere
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

      def self.field_queries(params)
        # Only handles 'q' and basic field/subfield searches

        query_strings = []
        # We skip all query types that are handled elsewhere
        params.each do |name, value|
          next if value.blank?
          next if name =~ /^.+\.(before|after)$/

          if name == 'q'
            query_strings << [value, 'fields' => ['_all']]
          else
            field = V1::Schema.flapping('item', name)

            # it probably has some kind of modifier
            next if field.nil?

            next if field.geo_point?

            query_strings << [ value, 'fields' => field.subfields? ? field.subfield_names : [field.name] ]
          end
        end

        query_strings.map {|query| Array.wrap(query)}
      end
      
      def self.date_range_queries(params)
        ranges = []
        params.each do |name, value|
          next unless name =~ /^(.+)\.(before|after)$/
          field_name = $1
          modifier = $2

          if modifier == 'after' #  params['temporal.after']
            limits = { :gte => value }
            # uncomment the below to enforce a strict "between" query rather than the
            # the default "if there is any overlap in timeframes" we use now.
            #limits[:lte] = params['temporal.before'] if params['temporal.before']
            ranges << ["#{field_name}.end", limits]
          elsif modifier == 'before'  #  params['temporal.before']
            limits = { :lte => value }
            # see above "between" comment
            #limits[:gte] = params['temporal.after'] if params['temporal.after']
            ranges << ["#{field_name}.start", limits]
          end
        end
        ranges
      end

      def self.range_queriesORIG(params)
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
