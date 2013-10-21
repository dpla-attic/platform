require_relative '../schema'
require_relative '../search_error'

module V1

  module Searchable

    module Filter

      # Default geo.distance "range" value
      DEFAULT_GEO_DISTANCE = '20mi'

      def self.build_all(resource, search, params)
        # Returns boolean for "did we run any filters?"

        filters = build_filters(resource, params)

        filters.each do |filter|
          search.filter(*filter)
        end

        filters.any?
      end

      def self.build_filters(resource, params)
        filters = []
        params.each do |name, value|
          next if value.to_s == ''
          
          field = field_for(resource, name)
          next if field.nil?
          filter = nil
          
          if field.date? || field.multi_field_date?
            date = parse_date_query(value)
            raise BadRequestSearchError, "Invalid date in #{name} field" if date.nil?
            
            filter = date_range(name, date)
          elsif field.geo_point?
            filter = value =~ /:/ ? geo_bounding_box(name, value) : geo_distance(name, params)
          end

          filters << filter if filter
        end

        filters
      end

      def self.parse_date_query(value)
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

      def self.date_range(name, date)
        [
          'range',
          name => {
            'gte' => date,
            'lt' => calculate_end_date(date)
          }
        ]
      end

      def self.calculate_end_date(date)
        # This is how we add one logical "increment" to a date like '1999-11'
        # to create '2000-01' as the non-inclusive upper bound for a date 
        # range. Handles dates formatted like YYYY, YYYY-MM and YYYY-MM-DD.
        format = '%Y-%m-%d'

        parts = date.split('-').map {|x| x.to_i }
        trimmed_format = format.split('-').first(parts.size).join('-')
        new_date = Date.new(*parts)

        if parts.size == 1
          new_date = new_date.next_year
        elsif parts.size == 2
          new_date = new_date.next_month
        else
          new_date = new_date.next_day
        end

        new_date.strftime(trimmed_format)
      end

      def self.geo_distance(name, params)
        distance_name = name.gsub(/^(.+)\.(.+)$/, '\1.distance')
        distance = DEFAULT_GEO_DISTANCE

        if params[distance_name].to_s != ''
          if params[distance_name] =~ /(mi|km)$/
            distance = params[distance_name]
          else
            raise BadRequestSearchError, "Missing or invalid units for #{distance_name}"
          end
        end
        
        #TODO: set _cache => true and test behavior
        [ 'geo_distance', name => params[name], 'distance' => distance ]
      end

      def self.geo_bounding_box(name, corners)
        if corners =~ /(.+):(.+)/
          [ 'geo_bounding_box', { name => { 'top_left' => $1, 'bottom_right' => $2 } } ]
        else
          raise BadRequestSearchError, "Malformed bounding_box coordinates for query on #{name}"
        end
      end

      def self.field_for(resource, name)
        Schema.field(resource, name)
      end
      
    end

  end

end
