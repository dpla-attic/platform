require 'active_support/core_ext'

module V1

  module Searchable

    module Filter

      # Default spatial.distance "range" value
      DEFAULT_SPATIAL_DISTANCE = '20mi'

      def self.spatial_coordinates_filter(params)
        #TODO: validate spatial.distance units
        return nil unless params['spatial.coordinates'].present?
        
        coordinates = params['spatial.coordinates']
        distance = params['spatial.distance'].presence || DEFAULT_SPATIAL_DISTANCE

        ['geo_distance', 'spatial.coordinates' => coordinates, 'distance' => distance]
      end

    end

  end

end
