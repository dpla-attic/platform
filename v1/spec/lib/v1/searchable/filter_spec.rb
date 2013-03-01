require 'v1/searchable/filter'

module V1

  module Searchable

    describe Filter do      
      let(:resource) { 'test_resource' }
      
      context "Constants" do

        describe "DEFAULT_GEO_DISTANCE" do
          it "has the correct value" do
            expect(Filter::DEFAULT_GEO_DISTANCE).to eq '20mi'
          end
        end

      end

      describe "#build_all" do
        it "applies the spatial_coordinates filter if one was generated from the params" do
          subject.stub(:geo_coordinates_filter) { ['fake', 'filter'] }
          search = mock(:filter => nil)
          search.should_receive(:filter).with(*['fake', 'filter'])
          subject.build_all(resource, search, stub)
        end

        it "does not apply the spatial_coordinates filter if one was not generated from the params" do
          subject.stub(:geo_coordinates_filter) { nil }
          search = mock(:filter => nil)
          search.should_not_receive(:filter)
          subject.build_all(resource, search, stub)
        end
        
      end

      describe "#geo_coordinates_filter" do

        it "handles coordinate queries without a range" do
          name = 'some_field.coordinates'
          V1::Schema.stub(:field).with(resource, name) { stub(:geo_point? => true) }
          params = {name => "42.1,-71"}
          expect(
                 subject.geo_coordinates_filter(resource, params)
                 ).to eq ['geo_distance', {name => "42.1,-71", 'distance' => Filter::DEFAULT_GEO_DISTANCE} ]
        end
        
        it "handles coordinate queries with a range" do
          name = 'some_field.coordinates'
          V1::Schema.stub(:field).with(resource, name) { stub(:geo_point? => true) }
          params = {name => "42.1,-71", 'some_field.distance' => '11mi'}
          expect(
                 subject.geo_coordinates_filter(resource, params)
                 ).to eq ['geo_distance', {name => "42.1,-71", 'distance' => '11mi'} ]
        end

        it "returns nil when there is no coordinates_field query" do
          name = 'q'
          params = {name => 'banana'}
          V1::Schema.stub(:field).with(resource, name)
          expect(
                 subject.geo_coordinates_filter(resource, params)
                 ).to eq nil
        end

        it "raises an API-specific exception if spatial.distance is supplied but lacks units" do
          name = 'some_field.coordinates'
          V1::Schema.stub(:field).with(resource, name) { stub(:geo_point? => true) }
          params = {name => "42.1,-71", 'some_field.distance' => '11'}
          expect {
            subject.geo_coordinates_filter(resource, params)
          }.to raise_error V1::BadRequestSearchError, "Missing or invalid units for some_field.distance"
        end

      end

    end
  end

end
