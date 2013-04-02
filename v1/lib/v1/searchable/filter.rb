require 'v1/schema'
require 'v1/search_error'

module V1

  module Searchable

    module Filter

      # Default geo.distance "range" value
      DEFAULT_GEO_DISTANCE = '20mi'
      # def self.build_all(resource, search, params)
      #   # Returns boolean for "did we run any filters?"
      #   geo_coordinates = geo_coordinates_filter(resource, params)
      #   if geo_coordinates
      #     search.filter(*geo_coordinates)
      #     true
      #   else
      #     false
      #   end
      # end

      def self.build_all(resource, search, params)
        # Returns boolean for "did we run any filters?"

        filters = build_geo_filters(resource, params)
        filters.each do |filter|
          search.filter(*filter)
        end

        filters.any?
      end
      
      def self.build_geo_filters(resource, params)
        filters = []
        params.each do |name, value|
          field = V1::Schema.field(resource, name)
          next unless field && field.geo_point?

          if value =~ /:/
            filters << geo_bounding_box(name, value)
          else
            filters << geo_distance(name, params)
          end
        end
        filters
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

      # def self.geo_coordinates_filterDEPRECATED(resource, params)
      #   filters = []
      #   params.each do |name, value|
      #     #TODO: Have a list of geo_point field names, then do string compares here.
      #     # V1::Schema.fields('geo_point') maybe? 
      #     field = V1::Schema.field(resource, name)
      #     if field && field.geo_point?
      #       coordinates = value

      #       # if there's no colon, treat it like geo_distance, else, geo_bounding_box
      #       if coordinates =~ /:/
      #         #geo_bounding_box
      #       else
      #         #geo_distance
              
      #         return geo_distance(coordinates
      #       distance_name = name.gsub(/^(.+)\.(.+)$/, '\1.distance')

      #       if params[distance_name].to_s != ''
      #         if params[distance_name] !~ /(mi|km)$/
      #           raise BadRequestSearchError, "Missing or invalid units for #{distance_name}"
      #         end
      #         distance = params[distance_name]
      #       else
      #         distance = DEFAULT_GEO_DISTANCE
      #       end
            
      #       #TODO: set _cache => true and test behavior
      #       return ['geo_distance', name => coordinates, 'distance' => distance]
      #     end
      #   end
      #   return nil
      # end

    end

  end

end
