require 'v1/schema'
require 'active_support/core_ext'

module V1

  module Searchable

    module Facet

      def self.build_all(search, options={})
        # Run facets for options[:facets], against the search object
        #TODO: support wildcard facet
        requested = options[:facets]
        return false if requested.blank?

        field_list = requested == '*' ? [] : requested.split(',')
        global = options.has_key?(:global) ? options[:global] : false

        field_list.each do |field|
          search.facet(field, :global => global) do |faceter|
            faceter.send(facet_type(field), field)
          end
        end

        field_list.any?
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
