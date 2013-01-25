require 'v1/schema'
require 'v1/search_error'

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
      DATE_INTERVALS = %w( year quarter month week day )
      DEFAULT_FACET_SIZE = 20
      MAXIMUM_FACET_SIZE = 50

      def self.build_all(search, params, global=false)
        # Run facets from params['facets'] against the search object
        # Returns boolean for "did we create any facets?"

        requested = params['facets'].to_s.split(/,\s*/)
        return false if requested.empty?

        requested = expand_facet_fields('item', requested)

        requested.each do |name|
          # Strip any modifiers from geo_distance or date facets
          field = parse_facet_name(name)

          if field.nil?
            raise BadRequestSearchError, "Invalid field(s) specified in facets param: #{name}"
          end
          
          # date facets with intervals retain the interval as part of their facet name
          facet_name = field.name
          facet_name += ".#{field.facet_modifier}" if field.date? && field.facet_modifier

          type = facet_type(field)

          options = facet_options(field)

          # only facet type (that we support) that supports size attr
          #TODO: fold into facet_options and base it on field.string?
          options[:size] = facet_size(params) if type == 'terms'
          options[:order] = 'count' unless field.geo_point?
          
          # geo_distance facets get called differently than other types of facets
          if type == 'geo_distance'
            facet_params = [type, options]
          else
            facet_params = [type, facet_field(field), options]
          end

          search.facet(facet_name, :global => global) do |faceter|
            faceter.send(*facet_params)
          end
        end

        requested.any?
      end

      def self.facet_size(params)
        size = params['facet_size'] == 'max' ? MAXIMUM_FACET_SIZE : params['facet_size']
        if size.to_s == ''
          DEFAULT_FACET_SIZE
        elsif size.to_i > MAXIMUM_FACET_SIZE
          MAXIMUM_FACET_SIZE
        else
          size
        end
      end

      def self.parse_facet_name(name)
        # Handles logic of parsing different types of facets and their optional modifier suffixes
        args = [name]
        if name =~ /^(.+?):(.*)$/
          # geo_distance
          args = [$1, $2]
        elsif (name =~ /^(.+)\.(.*)$/ && DATE_INTERVALS.include?($2))
          # date with interval
          args = [$1, $2]
        end
        # the gist here is that args may contain a facet_modifier
        V1::Schema.flapping('item', *args)
      end

      def self.facet_options(field)
        # Returns options for variable facet types.
        # Expects valid Field instance
        if field.geo_point?
          lat, long, bucket_size = field.facet_modifier.to_s.split(':')
          
          if lat.nil? or long.nil?
            raise BadRequestSearchError, "Facet '#{field.name}' missing lat/lon modifiers"
          end
          
          options = {
            field.name => "#{lat},#{long}",
            'ranges' => geo_facet_ranges(bucket_size),
            'unit' => bucket_size =~ /([a-z]{2})$/ ? $1 : 'mi'
          }
        elsif field.date?
          # Grab interval from date facet if it looks like one
          # Tire requires symbol keys in this hash

          # Tire defaults to 'day' too, but we set it here to improve testability
          default_interval = 'day'
          
          if field.facet_modifier
            if DATE_INTERVALS.include?(field.facet_modifier)
              #TODO: how do we want to handle timezones here?
              options = {:interval => field.facet_modifier } 
#              options[:pre_zone] = '-12:00'
#              options[:pre_zone_adjust_large_interval] = true
            else
              raise BadRequestSearchError, "Date facet '#{field.name}.#{field.facet_modifier}' has invalid interval"
            end
          else
            options = {:interval => default_interval } 
          end
        end

        options || {}
      end

      def self.geo_facet_ranges(bucket_modifier)
        # Generate ranges (or "buckets") with default values, for geo_facets
        # Arbitrary number of buckets to generate. Should be dictated by system tuning
        max_buckets = 8
        # Arbitrary bucket size.
        default_bucket_size = 100
        
        bucket_modifier =~ /^(\d+)/
        size = ($1 || default_bucket_size).to_i

        ranges = 1.upto(max_buckets).map do |i|
          { 'from' => i * size, 'to' => i * size + size }
        end

        [ { 'to' => size }, *ranges, { 'from' => max_buckets * size + size } ]
      end

      def self.facet_type(field)
        # Returns correct facet type based on field type. Defaults to terms.
        # Expects valid Field instance
        types = {
          'geo_point' => 'geo_distance',
          'date' => 'date'
        }
        types[field.type] || 'terms'
      end

      def self.facet_field(field)
        # Determines what field (not name) to tell ElasticSearch to use for a facet on this field
        # Expects valid Field instance
        if field.multi_fields.any? {|mf| (mf.name == field.name + '.raw') && mf.facetable?}
          # facetable multi_field with our standard .raw subfield
          field.name + '.raw'
        else
          field.name
        end
      end
      
      def self.expand_facet_fields(resource, names)
        # Expands a list of names into all facetables names and those names' facetable subnames
        # Passes unrecognized facet names through un-touched so they can be handled elsewhere
        #TODO: support wildcard facet '*'
        expanded = []
        names.each do |name|
          field = V1::Schema.flapping(resource, name)

          new_facets = []
          if field.nil?
            # allow unmapped fields to pass through so they can be handled elsewhere
            new_facets << name
          else
            # top level field is facetable
            new_facets << name if field.facetable?

            field.subfields.each do |subfield|
              new_facets << subfield.name if subfield.facetable?
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
