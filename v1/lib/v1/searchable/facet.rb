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
      DATE_INTERVALS = %w( century decade year month week day )
      DEFAULT_FACET_SIZE = 50
      MAXIMUM_FACET_SIZE = 2000
      DEFAULT_GEO_DISTANCE_MILES = 100
      DEFAULT_GEO_BUCKETS = 20

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
          
          type = facet_type(field)
          options = facet_options(type, field, params)

          # geo_distance facets get called differently than other types of facets
          if type == 'geo_distance'
            facet_params = [type, options]
          else
            facet_params = [type, facet_field_name(field), options]
          end

          search.facet(facet_display_name(field), :global => global) do |faceter|
            faceter.send(*facet_params)
          end
        end

        requested.any?
      end

      def self.facet_display_name(field)
        if field.date? && field.facet_modifier
          field.name + ".#{field.facet_modifier}"
        else
          field.name
        end
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
        V1::Schema.field('item', *args)
      end

      def self.facet_options(type, field, params)
        # Returns options for variable facet types.

        # NOTE: Tire requires the :interval key in options, if present, to be a symbol
        options = {}
        
        if type == 'geo_distance'
          lat, long, bucket_size = field.facet_modifier.to_s.split(':')
          if lat.nil? or long.nil?
            raise BadRequestSearchError, "Facet '#{field.name}' missing lat/lon modifiers"
          end

          #TODO: use one regex
          range_size = bucket_size =~ /^(\d+)/ ? $1 : DEFAULT_GEO_DISTANCE_MILES
          options = {
            field.name => "#{lat},#{long}",
            'ranges' => facet_ranges(range_size, range_size, DEFAULT_GEO_BUCKETS, true),
            'unit' => bucket_size =~ /([a-z]{2})$/ ? $1 : 'mi'
          }
        elsif type == 'date'
          if field.facet_modifier && !DATE_INTERVALS.include?(field.facet_modifier)
            raise BadRequestSearchError, "Date facet '#{field.name}.#{field.facet_modifier}' has invalid interval"
          end

          #TODO: how do we want to handle timezones here?
          #              options[:pre_zone] = '-12:00'
          #              options[:pre_zone_adjust_large_interval] = true

          # Tire defaults to 'day' too, but we set it here to improve testability
          options = {
            :interval => field.facet_modifier || 'day',
            :order => 'count'
          }
        elsif type == 'range'
          # Each range covers 2000 years and ends on 2100, which is arbitrary
          end_year = 2100

          if field.facet_modifier == 'decade'
            size = 10
            range_count = 200
          elsif field.facet_modifier == 'century'
            size = 100
            range_count = 20
          else
            #TODO: is this even possible
            raise BadRequestSearchError, "Invalid range modifier '#{field.facet_modifier}'"
          end

          range_start = end_year - size * range_count
          options = {
            'field' => field.name,
            'ranges' => facet_ranges(range_start, size, range_count, false)
          }
        elsif type == 'terms'
          # terms facet. No other facet type supports size attr
          options = {
            :size => facet_size(params),
            :order => 'count'
          }
        end
        
        options
      end

      def self.facet_ranges(start, size, count, endcaps=false)
        start = start.to_i
        count = count.to_i
        size = size.to_i

        ranges = []
        count.times do |i|
          lower = start + (i * size)
          ranges << { 'from' => lower, 'to' => lower + size }
        end

        if endcaps
          # open ended ranges
          to = ranges.map {|range| range['from']}.min
          from = ranges.map {|range| range['to']}.max
          ranges = [ { 'to' => to }, *ranges, { 'from' => from } ]
        end

        # ElasticSearch needs to see string type data for date range facets to work
        ranges.each {|hash| hash.each {|k,v| hash[k] = v.to_s} }
      end

      def self.facet_type(field)
        # Returns correct facet type based on field type.
        if field.geo_point?
          'geo_distance'
        elsif field.date? && %w( decade century ).include?(field.facet_modifier)
          'range'
        elsif field.date?
          'date'
        else
          'terms'
        end
      end

      def self.facet_field_name(field)
        # Determines what field (not name) to tell ElasticSearch to use for a facet on this field
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
        expanded = []
        names.each do |name|
          new_facets = []

          field = V1::Schema.field(resource, name)
          if field
            # top level field is facetable
            new_facets << name if field.facetable?

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
