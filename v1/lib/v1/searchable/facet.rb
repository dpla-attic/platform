require 'v1/schema'
require 'v1/search_error'

module V1

  module Searchable

    module Facet
      #TODO: Decouple this from V1::Schema when we have the new Field class

      #TODO: Add support for integer and integer+unit(h|d|w) intervals
      DATE_INTERVALS = %w( year quarter month week day hour minute )

      def self.build_all(search, params, global=false)
        # Returns boolean for "did we run any filters?"
        # Run facets for options[:facets] against the search object
        requested = params['facets'].to_s.split(/,\s*/)
        return false if requested.empty?

        requested = V1::Schema.expand_facet_fields('item', requested)
        validate_params(requested)

        requested.each do |field|
          facet_name = field
          # pre-screen date facets with optional intervals defined
          options = date_facet_options(field)

          #TODO: only for date facets, convert from milli to sec.
          options[:post_zone] = '05:00'

          field = options.delete(:field) || field

          search.facet(facet_name, :global => global) do |faceter|
            faceter.send(facet_type(field), V1::Schema.facet_field(field), options)
          end
        end

        requested.any?
      end

      def self.validate_params(fields)
        # Validates that all requested facet fields are facetable. This assumes that
        # the fields list has already been expanded where necessary.
        invalid = fields.select do |field|
          original = field

          # trim interval string off date facet before checking if they are facetable
          if field =~ /(.+)\.(.*)$/ && DATE_INTERVALS.include?($2)
            field = $1
          end

          # return original string if base field fails facetable? test
          original if !V1::Schema.facetable?('item', field)
        end
        if invalid.any?
          raise BadRequestSearchError, "Invalid field(s) specified in facets param: #{invalid.join(',')}"
        end
      end

      def self.date_facet_options(field)
        if field =~ /(.+)\.(.*)$/ && DATE_INTERVALS.include?($2)
          # Tire requires symbols for keys here
          { :field => $1, :interval => $2 }
        else
          {}
        end
      end

      def self.facet_type(field)
        # Get mapping for field to determine what kind facet to create.
        # Supported types: terms, date.
        mapping = V1::Schema.item_mapping(field)
        return (mapping && mapping[:type] == 'date') ? :date : :terms
      end

    end

  end

end
