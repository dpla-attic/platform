require_relative '../search_error'
require_relative '../schema'
require_relative 'facet'


module V1

  module Searchable

    module FacetOptions

      DEFAULT_GEO_DISTANCE_MILES = 100
      DEFAULT_GEO_BUCKETS = 20
      DEFAULT_FACET_SIZE = 50
      MAXIMUM_FACET_SIZE = 2000

      def self.default_facet_size
        DEFAULT_FACET_SIZE
      end
      
      def self.maximum_facet_size
        MAXIMUM_FACET_SIZE
      end
      
      def self.default_geo_distance_miles
        DEFAULT_GEO_DISTANCE_MILES
      end

      def self.default_geo_buckets
        DEFAULT_GEO_BUCKETS
      end

      def self.build_options(type, field, params)
        # Returns options for variable facet types.

        # NOTE: Tire requires the :interval key in options, if present, to be a symbol
        #TODO: standardize strings/symbols as hash keys
        options = {}
        
        if type == 'geo_distance'
          lat, long, bucket_size = field.facet_modifier.to_s.split(':')
          if lat.nil? or long.nil?
            raise BadRequestSearchError, "Facet '#{field.name}' missing lat/lon modifiers"
          end

          #TODO: use one regex
          range_size = bucket_size =~ /^(\d+)/ ? $1 : default_geo_distance_miles
          options = {
            field.name => "#{lat},#{long}",
            'ranges' => facet_ranges(range_size, range_size, default_geo_buckets, true),
            'unit' => bucket_size =~ /([a-z]{2})$/ ? $1 : 'mi'
          }
        elsif type == 'date'
          if field.facet_modifier && !Facet.valid_date_interval?(field.facet_modifier)
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
          # Each range covers 2000 years and ends on 2100, which is just a number
          # that seems useful (it's not a magic number at all.)
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
            :order => 'count',
          }
          options.merge!(filter_facet(field.name, params))
        end
        
        options
      end

      def self.facet_size(params)
        size = params['facet_size'] == 'max' ? maximum_facet_size : params['facet_size']
        if size.to_s == ''
          default_facet_size
        elsif size.to_i > maximum_facet_size
          maximum_facet_size
        else
          size
        end
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


      def self.filter_facet(name, params)
        filtered = params['filter_facets'].to_s.split(/,\s*/)
        query = params[name].to_s
        return {} unless (filtered.include?(name) && query != '')
        
        words = query.split
        regex = nil

        #TODO: better support for multiple words *with* wildcards. Perhaps do the wildcard
        #pass first, then do current elsif block

        if query =~ /\*/
          #wildcards "so*city"
          regex = query.gsub(/\*/, '.*')
        elsif words.size == 1
          regex = words.first
        elsif query =~ /^"(.+)"$/
          #double-quoted string
          regex = $1
        elsif false
          #plus or minus signs
        elsif query =~ / OR /
          #multiple words with boolean operator
          # 1.9.3p194 :023 > 'foo bar baz' =~ Regexp.union(/bar/, /foo/i)
          regex = '(' + words.select {|w| w != 'OR'}.join('|') + ')'
        else
          # multiple bare words, emulates default_operator 'AND' in query_string queries
          # positive lookahead regex for each word
          regex = '' + words.map {|w| "(?=.*#{w})"}.join + ''
        end

        #TODO: Can we test that this is a valid regex first?
        # Regexp.try_convert(/#{regex}/) rescue false
        {
          "script_field" => "term.toLowerCase() ~= '.*#{regex.downcase}.*'"
        }
      end

    end

  end

end
