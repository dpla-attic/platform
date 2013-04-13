require 'v1/schema'
require 'v1/search_error'

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
          field = Schema.field(resource, name)
          next if field.nil?
          filter = nil
          
          if field.date?
            filter = date_range(name, value)
          elsif field.geo_point?
            filter = value =~ /:/ ? geo_bounding_box(name, value) : geo_distance(name, params)
          end

          filters << filter if filter
        end

        filters
      end

      def self.date_range(name, value)
        [ 'range', name => {'gte' => value, 'lte' => value} ]
      end

      # def self.build_geo_filters(resource, params)
      #   filters = []
      #   params.each do |name, value|
      #     field = Schema.field(resource, name)
      #     next unless field && field.geo_point?

      #     if value =~ /:/
      #       filters << geo_bounding_box(name, value)
      #     else
      #       filters << geo_distance(name, params)
      #     end
      #   end
      #   filters
      # end

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

    end

  end

end
