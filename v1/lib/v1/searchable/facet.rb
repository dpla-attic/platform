require 'v1/schema'
require 'v1/search_error'

module V1

  module Searchable

    module Facet
      #TODO: Decouple this from V1::Schema when we have the new Field class

      #TODO: Add support for integer and integer+unit(h|d|w) intervals or just let any
      # suffix through and let ElasticSearch complain if it is not valid
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

          #TODO: how do we want to handle timezones here?
          options[:post_zone] = '05:00'

          field = options.delete(:field) || field

          search.facet(facet_name, :global => global) do |faceter|
            faceter.send(facet_type(field), facet_field(field), options)
          end
        end

        requested.any?
      end

      def self.validate_params(names)
        # Validates that all requested facet fields are facetable.
        invalid = names.select do |name|
          original = name

          # trim interval string off date facet before checking if they are facetable
          if name =~ /(.+)\.(.*)$/ && DATE_INTERVALS.include?($2)
            name = $1
          end

          # return original string if base field fails facetable? test
          field = V1::Schema.flapping('item', name)
          original if !(field && field.facetable?)
        end
        if invalid.any?
          raise BadRequestSearchError, "Invalid field(s) specified in facets param: #{invalid.join(',')}"
        end
      end

      def self.date_facet_options(name)
        # TODO: allow arbitrary intervals (2d, 520w, etc.)
        if name =~ /(.+)\.(.*)$/ && DATE_INTERVALS.include?($2)
          # Tire requires symbols for keys here
          { :field => $1, :interval => $2 }
        else
          {}
        end
      end

      def self.facet_type(name)
        # Field type determines what type of facet it will create
        # Supported types: terms, date.
        # TODO: These might have to be symbols
        field = V1::Schema.flapping('item', name)
        field.type == 'date' ? 'date' : 'terms'
      end

      def self.facet_field(name)
        # Conditionally extend multi_field types to their .raw sub-field.
        # e.g. facet_field('isPartOf.name') => 'isPartOf.name.raw'
        field = V1::Schema.flapping('item', name)

        # strip interval off the end and return field name
        if !field && name =~ /(.+)\.(.*)$/ && DATE_INTERVALS.include?($2)
          return $1
        elsif field && field.multi_fields.select {|mf| mf.name == 'raw' && mf.facetable?}.any?
          # this has a facetable multi_field subfield
          name + '.raw'
        else
          name
        end
      end
      
    end

  end

end
