require 'v1/schema'
require 'active_support/core_ext'

module V1

  module Searchable

    module Query

      def self.build_all(resource, search, params)
        # Returns boolean for "did we run any queries?"
        string_queries = string_queries(resource, params)
        date_range_queries = date_range_queries(params)
        ids_queries = ids_query(resource, params)

        # Only call search.query.boolean if we have some queries to pass it.
        # Otherwise we'll get incorrect search results.
        return false if (string_queries + date_range_queries + ids_queries).empty?

        search.query do |query|
          if ids_queries.any?
            query.ids *ids_queries
          end

          query.boolean do |boolean|

            string_queries.each do |query_string|
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

      
      def self.ids_query(resource, params)
        # This is not actually available via the front-end, but it could be if we wanted
        ids = params['ids'].to_s
        return [] if ids == ''

        [ids.split(/,\s*/), resource]
      end

      def self.string_queries(resource, params)
        # Only handles 'q' and basic field/subfield searches

        query_strings = []
        params.each do |name, value|
          # Skip all query types that are handled elsewhere
          next if value.to_s == ''
          next if name =~ /^.+\.(before|after)$/
          pair = nil
          
          if name == 'q'
            pair = [ value, 'fields' => ['_all'] ]
          else
            field = Schema.field(resource, name)

            # it probably has some kind of modifier that we do not handle here
            next if field.nil?

            next if field.geo_point?

            fields = {
              'fields' => field.subfields? ? ["#{field.name}.*"] : [field.name]
            }
            pair = [ value, fields ]
          end

          pair << default_attributes.merge(pair.pop)
          query_strings << pair
        end

        query_strings.map {|query| Array.wrap(query)}
      end

      def self.default_attributes
        # Default attributes applies to all field queries
        {
          'default_operator' => 'AND',  # non-default behavior for unquoted mult-word queries
          'lenient' => true,            # ignore "query string from date field" type errors
        }
      end

      def self.date_range_queries(params)
        ranges = []
        params.each do |name, value|
          next unless name =~ /^(.+)\.(before|after)$/
          field_name = $1
          modifier = $2

          # Note the references to 9999 and -9999. Those exclude false positives from
          # null values in the field in question. See schema.rb where those defaults are defined.
          if modifier == 'after'
            # uncomment the below to enforce a strict "between" query rather than the
            # the default "if there is any overlap in timeframes" we use now.
            #limits[:lte] = params['temporal.before'] if params['temporal.before']
            ranges << ["#{field_name}.end", { :gte => value, :lt => '9999' }]
          elsif modifier == 'before'
            # see above "between" comment
            #limits[:gte] = params['temporal.after'] if params['temporal.after']
            ranges << ["#{field_name}.begin", { :lte => value, :gt => '-9999' }]
          end
        end
        ranges
      end

    end

  end

end
