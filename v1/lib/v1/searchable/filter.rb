require 'active_support/core_ext'

module V1

  module Searchable

    module Filter

      # Default spatial.distance "range" value
      DEFAULT_SPATIAL_DISTANCE = '20mi'

      def self.build_all(search, params)
        # Returns boolean for "did we run any filters?"
        spatial_filter = spatial_coordinates_filter(params)
        if spatial_filter
          search.filter(*spatial_filter)
          true
        end
        false
      end
      
      def self.spatial_coordinates_filter(params)
        return nil unless params['spatial.coordinates'].present?
        
        coordinates = params['spatial.coordinates']
        distance = params['spatial.distance'].presence || DEFAULT_SPATIAL_DISTANCE

        ['geo_distance', 'spatial.coordinates' => coordinates, 'distance' => distance]
      end

    end

  end

end
