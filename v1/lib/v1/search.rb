require 'v1/schema'

module V1

  module Search

    def self.build_facets(search, options)
      #TODO: test
      # Run facets for options[:facets], against the search object
      #TODO: support wildcard facet
      field_list = options[:facets] == '*' ? [] : options[:facets].split(',')
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
