require 'v1/searchable/filter'

module V1

  module Searchable

    module Filter

      describe Filter do      
        
        context "Constants" do

          describe "DEFAULT_SPATIAL_DISTANCE" do
            it "has the correct value" do
              expect(DEFAULT_SPATIAL_DISTANCE).to eq '20mi'
            end
          end

        end

        describe "#spatial_coordinates_filter" do

          it "handles coordinate queries without a range" do
            params = {'spatial.coordinates' => "42.1,-71"}
            expect(
                   subject.spatial_coordinates_filter(params)
                   ).to eq ['geo_distance', {'spatial.coordinates' => "42.1,-71", 'distance' => DEFAULT_SPATIAL_DISTANCE} ]
          end
          
          it "handles coordinate queries with a range" do
            params = {'spatial.coordinates' => "42.1,-71", 'spatial.distance' => '11mi'}
            expect(
                   subject.spatial_coordinates_filter(params)
                   ).to eq ['geo_distance', {'spatial.coordinates' => "42.1,-71", 'distance' => '11mi'} ]
          end

          it "returns nil when there is no spatial.coordinates query" do
            params = {'q' => 'banana'}
            expect(
                   subject.spatial_coordinates_filter(params)
                   ).to eq nil
          end

        end

      end
    end

  end

end
