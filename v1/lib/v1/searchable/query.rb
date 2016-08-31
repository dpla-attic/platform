require_relative '../schema'
require_relative '../search_error'
require_relative '../field_boost'
require 'active_support/core_ext'

module V1

  module Searchable

    module Query

      # not escaped, but probably could be if escape code was tweaked: '&&', '||'
      # not escaped, because they don't seem to need it: '+', '-',
      ESCAPED_METACHARACTERS = [ '!', '(', ')', '{', '}', '[', ']', '^', '~', '?', ':', '/' ]  # '"',

      def self.execute_empty_search(search)
        # We need to be explicit with an empty search
        search.query { |q| q.all }
      end

      # @param resource [String] "item" or "collection"
      # @param search [Tire::Search::Search]
      # @param params [Hash]
      def self.build_all(resource, search, params)
        # Returns boolean for "did we run any queries?"
        string_queries = string_queries(resource, params)
        date_range_queries = date_range_queries(params)
        # ids_queries = ids_query(resource, params)
        
        # Only call search.query.boolean if we have some queries to pass it.
        # Otherwise we'll get incorrect search results.
        if (string_queries + date_range_queries).empty?
          execute_empty_search(search)
          return false
        end

        search.query do |query|
          # if ids_queries.any?
          #   query.ids *ids_queries
          # end
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

      def self.escaped_metacharacters
        ESCAPED_METACHARACTERS
      end

      def self.protect_metacharacters(string, exact_field_match=false)
        # Note that we preserve double-quote wrapping, which needs no escaping
        tmp = string.dup
        if tmp =~ /^"(.+)"$/
          tmp = $1
          quoted = true
        end

        # If the `exact_field_match' query parameter is true, then we need to
        # facilitate exact field matches by quoting strings with space
        # characters.
        quoted = true if exact_field_match

        escaped_metacharacters.each do |mc|
          # Try: tmp.gsub!(/(?=#{mc})/, '\\') #=> Foo\ Bar\!
          tmp.gsub!(mc, '\\' + mc)
        end
        
        # How do we handle this query: '"Toast" AND "Bread Trucks"'
        # and also handle: '1 and 3/8" boards'
        if tmp.count('"') % 2 == 1
          tmp.gsub!(/"/, '\\"')
          tmp.gsub!(/\\{2,}"/, '\\"')
        end
        
        quoted ? %Q("#{tmp}") : tmp
      end

      def self.string_queries(resource, params)
        query_strings = []

        # exact_field_match: Whether to match exactly with the not_analyzed
        # index for a field, vs. doing a tokenized search for parts of the
        # string.  E.g. "University of Pennsylvania" -- search for exactly
        # that string, or for ("University" OR "Pennsylvaina")?
        exact_field_match_param = params['exact_field_match'].to_s == 'true'

        params.each do |name, value|
          # Skip all query types that are handled elsewhere
          next if value.to_s == ''
          next if name =~ /^.+\.(before|after)$/

          if name == 'q'
            fields = field_boost_for_all(resource) + ['_all']
            # The `q' parameter always wants a tokenized search, so we won't
            # ask for it to be quoted below in our call to
            # `.protect_metacharacters'.
            exact_field_match = false
          else
            exact_field_match = exact_field_match_param

            # Assigns a V1::Field
            # Note that this returns nil for parameters that are not field
            # names (e.g. "sort_by" or "callback").
            field = field_for(resource, name)

            next if field.nil? || field.date? || field.multi_field_date? || field.geo_point?

            if field.compound_fields
              # Assign `fields` as the corresponding analyzed fields.
              #
              # The only field that has compound fields is
              # admin.contributingInstitution.
              #
              # Override the field names of "compound fields" (i.e. in
              # admin.contributingInstitution) only if the "exact fields"
              # option has not been selected.  (See .parse_compound_fields)
              if exact_field_match
                fields = field.compound_fields
              else
                fields = parse_compound_fields(field.compound_fields)
              end

            else
              fields = field_boost_deep(resource, field)
            end 
          end

          query_strings << [
                            protect_metacharacters(value, exact_field_match),
                            default_attributes.merge({'fields' => fields})
                           ]
        end

        query_strings
      end
      
      def self.field_for(resource, name)
        Schema.field(resource, name)
      end
      
      def self.field_boost_for_all(resource)
        FieldBoost.for_resource(resource).map do |name, boost|
          field = field_for(resource, name)
          field_boost(resource, field) if field
        end.compact
      end

      ##
      # Return the string representation of the given field appended with ".*"
      # if the field has subfields, and appended with a boost ("^")
      # phrase if the field is supposed to be boosted per our configuration
      # in v1/config/dpla.yml.
      #
      # @example
      #
      #   Let sourceResource.title be given a boost of 2 in v1/config/dpla.yml:
      #
      #   field = V1::Schema.field('item', 'sourceResource.title')
      #   V1::Searchable::Query.field_boost('item')
      #   => "sourceResource.title^2"
      #
      #   Let sourceResource.subject be given a boost of 0.8 in dpla.yml.  It
      #   has subfields.
      #
      #   field = V1::Schema.field('item', 'sourceResource.subject')
      #   V1::Searchable::Query.field_boost('item', field)
      #   => "sourceResource.subject.*^0.8"
      #
      #   Where sourceResource.collection has no boost in dpla.yml and has
      #   subfields:
      #
      #   field = V1::Schema.field('item', 'sourceResource.collection')
      #   V1::Searchable::Query.field_boost('item', field)
      #   => "sourceResource.collection.*"
      #
      # @see https://www.elastic.co/guide/en/elasticsearch/reference/0.90/query-dsl-query-string-query.html#_boosting_2
      #
      # @return String
      #
      def self.field_boost(resource, field)
        name = field.name
        name += ".*" if field.subfields?

        boost = field_boost_for(resource, field)
        name += "^#{boost}" if boost

        name
      end

      ##
      # Return an array of strings representing the subfields of the given
      # field as appended by .field_boost.
      #
      # In actual practice, we at the DPLA have never made use of these
      # deep field boosts.  Calls to field_boost_deep tend to return an array
      # of a single string element that would have been returned by
      # .field_boost.
      #
      # @example
      #
      #   Let sourceResource.collection.title be given a boost of 2. Note that
      #   sourceResource.collection has subfields `id', `description', and
      #   `title'.
      #
      #   field = V1::Schema.field('item', 'sourceResource.collection')
      #   V1::Searchable::Query.field_boost_deep('item', field)
      #   => ["sourceResource.collection.*",
      #       "sourceResource.collection.title^2"]
      #
      # @see self.field_boost
      # @return Array  Array of String
      #
      def self.field_boost_deep(resource, field)
        boosted_subfields = field.subfields.map do |subfield|
          field_boost(resource, subfield) if is_boosted?(resource, subfield)
        end

        [field_boost(resource, field)] + boosted_subfields.compact
      end

      def self.is_boosted?(resource, field)
        FieldBoost.is_boosted?(resource, field.name)
      end

      def self.field_boost_for(resource, field)
        FieldBoost.for_field(resource, field.name)
      end

      def self.default_attributes
        # Default attributes applies to all field queries
        {
          'default_operator' => 'AND',  # non-default behavior for unquoted mult-word queries
          'lenient' => true,            # ignore "query string from date field" type errors
        }
      end

      def self.parse_date_query(value)
        #TODO: consolidate with filter.rb's version of this
        # Returns nil for values don't match any of our partial or full date formats
        # Does not detect stuff like 1998-02-31

        # As a courtesy, remove double-quote wrapping
        date = value =~ /^"(.+)"$/ ? $1 : value
        if date.split('-').any? {|x| x.to_i == 0}
          nil
        else
          date
        end
      end


      def self.date_range_queries(params)
        #TODO: Reimplement as a filter like Filter.date_range()
        ranges = []
        params.each do |name, value|
          next unless name =~ /^(.+)\.(before|after)$/
          field_name = $1
          modifier = $2

          if parse_date_query(value).nil?
            raise BadRequestSearchError, "Invalid date in #{name} field"
          end

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

      private

      ##
      # Remove substring ".not_analyzed" from end of each field name in the
      # given array.
      #
      # This method would be better named `analyzed_fields` or inlined into
      # self.string_queries.
      #
      # @param field_names [Array]
      # @return Array
      def self.parse_compound_fields(field_names)
        field_names.map do |name|
          name.gsub(/.not_analyzed\z/, "")
        end
      end

    end

  end

end
