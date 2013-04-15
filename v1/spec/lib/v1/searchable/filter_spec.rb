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

        let(:built_filters) {
          [
           ['distance', 'coords' => '42,-71'],
           ['bbox', 'left' => '41,-70', 'right' => '43,-72'],
           ['range', 'datefield' => {'gte' => '1973', 'lte' => '1973'}],
          ]
        }
        
        it "Passes all the generated filters to its search arg" do
          subject.stub(:build_filters).with(resource, anything()) { built_filters } 

          search = mock(:filter => nil)
          search.should_receive(:filter).with( *['distance', 'coords' => '42,-71'])
          search.should_receive(:filter).with( *['bbox', 'left' => '41,-70', 'right' => '43,-72'])

          subject.build_all(resource, search, stub)
        end

        it "returns true if it generated any filters" do
          subject.stub(:build_filters).with(resource, anything()) { built_filters } 

          search = mock(:filter => nil)
          expect(subject.build_all(resource, search, stub)).to be_true
        end
        
      end

      describe "#date_range" do
        let(:expected_range) { [ 'range', 'datefield' => {'gte' => '1973', 'lt' => '1974'} ] }

        it "strips double-quote wrapping from dates" do
          expect(subject.date_range('datefield', '"1973"')).to eq( expected_range )
        end
        it "returns the expected array" do
          expect(subject.date_range('datefield', '1973')).to eq( expected_range )
        end
      end

      describe "#calculate_end_date" do
        it "handles year" do
          expect(subject.calculate_end_date('2012')).to eq '2013'
        end
        it "handles year-month" do
          expect(subject.calculate_end_date('2012-03')).to eq '2012-04'
        end
        it "handles year-month-day" do
          expect(subject.calculate_end_date('2012-03-04')).to eq '2012-03-05'
        end
      end

      describe "#geo_distance" do

        it "handles coordinate queries without a range" do
          name = 'some_field.coordinates'
          params = {name => "42.1,-71"}
          expect(
                 subject.geo_distance(name, params)
                 ).to eq ['geo_distance', {name => "42.1,-71", 'distance' => Filter::DEFAULT_GEO_DISTANCE} ]
        end
        
        it "handles coordinate queries with a range" do
          name = 'some_field.coordinates'

          params = {name => "42.1,-71", 'some_field.distance' => '11mi'}
          expect(
                 subject.geo_distance(name, params)
                 ).to eq ['geo_distance', {name => "42.1,-71", 'distance' => '11mi'} ]
        end

        it "raises an API-specific exception if spatial.distance is supplied but lacks units" do
          name = 'some_field.coordinates'

          params = {name => "42.1,-71", 'some_field.distance' => '11'}
          expect {
            subject.geo_distance(name, params)
          }.to raise_error BadRequestSearchError, "Missing or invalid units for some_field.distance"
        end

      end

    end
  end

end
