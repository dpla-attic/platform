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

        describe "#build_all" do
          it "does apply the spatial_coordinates filter if one was generated from the params" do
            subject.stub(:spatial_coordinates_filter) { ['fake', 'filter'] }
            search = mock(:filter => nil)
            search.should_receive(:filter).with(*['fake', 'filter'])
            subject.build_all(search, stub)
          end

          it "does not apply the spatial_coordinates filter if one was not generated from the params" do
            subject.stub(:spatial_coordinates_filter) { nil }
            search = mock(:filter => nil)
            search.should_not_receive(:filter)
            subject.build_all(search, stub)
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

          it "raises an API-specific exception if spatial.distance is supplied but lacks units"

        end

      end
    end

  end

end
