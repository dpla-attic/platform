require 'v1/schema'
require 'v1/search_error'
require 'active_support/core_ext'

module V1

  module Searchable

    module Facet

      def self.build_all(search, params, global=false)
        # Returns boolean for "did we run any filters?"
        # Run facets for options[:facets] against the search object
        requested = params['facets'].to_s.split(',')
        return false if requested.empty?

        requested = V1::Schema.expand_facet_fields('item', requested)
        validate_params(requested)

        requested.each do |field|
          search.facet(field, :global => global) do |faceter|
            faceter.send(facet_type(field), V1::Schema.facet_field(field))
          end
        end

        requested.any?
      end

      def self.validate_params(fields)
        # Validates that all requested facet fields are facetable. This assumes that
        # the fields list has already been expanded where necessary.
        invalid = fields.select {|field| !V1::Schema.facetable?('item', field)}
        if invalid.any?
          raise BadRequestSearchError, "Invalid field(s) specified in facets param: #{invalid.join(',')}"
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
