require 'v1/schema'
require 'v1/search_error'

module V1

  module Searchable

    module Filter

      # Default geo.distance "range" value
      DEFAULT_GEO_DISTANCE = '20mi'

      def self.build_all(resource, search, params)
        # Returns boolean for "did we run any filters?"
        geo_filter = geo_coordinates_filter(resource, params)
        if geo_filter
          search.filter(*geo_filter)
          true
        else
          false
        end
      end
      
      def self.geo_coordinates_filter(resource, params)
        params.each do |name, value|
          field = V1::Schema.field(resource, name)
          if field && field.geo_point?
            coordinates = value
            distance_name = name.gsub(/^(.+)\.(.+)$/, '\1.distance')

            if params[distance_name].to_s != ''
              if params[distance_name] !~ /(mi|km)$/
                raise BadRequestSearchError, "Missing or invalid units for #{distance_name}"
              end
              distance = params[distance_name]
            else
              distance = DEFAULT_GEO_DISTANCE
            end
            
            #TODO: set _cache => true and test behavior
            return ['geo_distance', name => coordinates, 'distance' => distance]
          end
        end
        return nil
      end

    end

  end

end
