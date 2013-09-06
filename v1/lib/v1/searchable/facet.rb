require_relative '../search_error'
require_relative '../schema'
require_relative 'facet_options'

module Tire
  module Search
    class Facet
      def geo_distance(options={})
        @value = { :geo_distance => { }.update(options) }
      end
    end
  end
end

module V1

  module Searchable

    module Facet
      #TODO: Add support for integer and integer+unit(h|d|w) intervals or just let any
      # suffix through and let ElasticSearch complain if it is not valid
      # ElasticSearch's built-in intervals
      VALID_DATE_INTERVALS = %w( century decade year month day )
      FILTER_FACET_FLAGS = %w( CASE_INSENSITIVE DOTALL )

      def self.valid_date_intervals
        VALID_DATE_INTERVALS
      end
      
      def self.filter_facet_flags
        FILTER_FACET_FLAGS
      end

      def self.valid_date_interval?(interval)
        valid_date_intervals.include?(interval)
      end

      def self.build_all(resource, search, params, global=false)
        # Run facets from params['facets'] against the search object
        # Returns boolean for "did we create any facets?"
        requested = params['facets'].to_s.split(/,\s*/)
        return false if requested.empty?

        requested = expand_facet_fields(resource, requested)

        requested.each do |name|
          field = parse_facet_name(resource, name)

          if field.nil?
            raise BadRequestSearchError, "Invalid field(s) specified in facets param: #{name}"
          end

          if !field.facetable?
            raise BadRequestSearchError, "Non-facetable field(s) specified in facets param: #{name}"
          end
          
          global_hash = global ? {:global => true} : {}
          search.facet(facet_display_name(field), global_hash) do |faceter|
            faceter.send(*build_facet_params(field, params))
          end
        end

        requested.any?
      end

      def self.build_facet_params(field, params)
        type = facet_type(field)
        options = FacetOptions.build_options(type, field, params)

        if type == 'geo_distance'
          [type, options]
        else
          [type, facet_field_name(field), options]
        end
      end

      def self.facet_field_name(field)
        # Determines the name of the field to use for this facet. (Not to be confused
        # with what arbitrary name to call the facet in the results set.)
        if field.date?
          field.name
        elsif field.not_analyzed_field && field.not_analyzed_field.facetable?
          field.not_analyzed_field.name
        else
          field.name
        end
      end
      
      def self.facet_display_name(field)
        # Retrail the facet_modifier string for date fields to better support date_histogram
        # intervals in the facet payload returned to the client
        if (field.date? || field.multi_field_date?) && field.facet_modifier
          field.name + ".#{field.facet_modifier}"
        else
          field.name
        end
      end

      def self.parse_facet_name(resource, name)
        # Handles logic of parsing different types of facets and their optional modifier suffixes
        args = [name]
        if name =~ /^(.+?):(.*)$/
          # geo_distance
          args = [$1, $2]
        elsif (name =~ /^(.+)\.(.*)$/ && valid_date_interval?($2))
          # date with interval
          args = [$1, $2]
        end
        # the gist here is that args may contain a facet_modifier
        Schema.field(resource, *args)
      end

      def self.facet_type(field)
        # Returns correct facet type based on field type.
        if field.geo_point?
          'geo_distance'
        elsif (field.date? || field.multi_field_date?) && %w( decade century ).include?(field.facet_modifier)
          'range'
        elsif field.date? || field.multi_field_date?
          'date'
        else
          'terms'
        end
      end

      def self.expand_facet_fields(resource, names)
        # Expands a list of names into all facetables names and those names' facetable subnames
        # Passes unrecognized facet names through un-touched so they can be handled elsewhere
        expanded = []
        names.each do |name|
          new_facets = []

          field = Schema.field(resource, name)
          if field
            # top level field is facetable
            new_facets << field.name if field.facetable?

            field.subfields.each do |subfield|
              new_facets << subfield.name if subfield.facetable? && !subfield.geo_point?
            end
          end

          # Add any new facets we found, or just this facet name (which will get flagged by 
          # validation later) if we didn't find any.
          expanded << (new_facets.any? ? new_facets : name)
        end
        expanded.flatten
      end

    end

  end

end
