require 'v1/searchable/query'

module V1

  module Searchable

    describe Query do

      describe "#build_all" do
        #TODO: all new unit tests for completely refactored implementation

        # it "should set up proper 'boolean.must' blocks for each search field" do
        #   params = {'title' => 'title1'  , 'description' => 'description2'}
        #   subject.should_receive(:field_queries).with(params) { ['titleQString', 'descQString'] }
        #   mock_boolean = mock('boolean')
        #   subject.should_receive(:lambda).twice.and_yield(mock_boolean)

        #   mock_must = mock('must')
        #   mock_boolean.should_receive(:must).twice.and_yield(mock_must)

        #   mock_must.should_receive(:string).with('titleQString')
        #   mock_must.should_receive(:string).with('descQString')
        #   subject.build_field_queries(params)
        # end

        # it "returns generated queries as flattened array" do
        #   subject.stub(:build_field_queries) { [:fq1, :fq2] }
        #   subject.stub(:build_temporal_query) { [:tq1, :tq2] }
        #   expect(subject.build_all(stub, {})).to match_array [:fq1, :fq2, :tq1, :tq2]
        # end
      end


      describe "#field_queries" do
        it "returns correct query string for a free text search" do
          params = {'q' => 'something'}
          expect(subject.field_queries(params))
            .to match_array(
                            
                            [['something', {"fields"=>["_all"]}]]
                            )
        end
        
        it "returns correct query string for field search" do
          name = 'aggregatedCHO.title'
          field = stub(:name => name, :geo_point? => false, :subfields? => false)
          V1::Schema.stub(:field).with('item', name) { field }
          params = {name => 'some title'}
          expect(subject.field_queries(params))
            .to match_array(
                            
                            [['some title', {'fields' => [name], 'lenient' => true}]]
                            )
        end

        it "handles 'aggregatedCHO.spatial.state' as a normal field search" do
          name = 'aggregatedCHO.spatial.state'
          field = stub(:name => name, :geo_point? => false, :subfields? => false)
          V1::Schema.stub(:field).with('item', name) { field }
          params = {name => 'MA'}
          expect(subject.field_queries(params))
            .to match_array(
                            
                            [['MA', {'fields' => [name], 'lenient' => true}]]
                            )
        end


        it "ignores geo_point field" do
          name = 'aggregatedCHO.spatial.coordinates'
          field = stub(:name => name, :geo_point? => true)
          V1::Schema.stub(:field).with('item', name) { field }
          params = {name => '42,-71'}
          expect(subject.field_queries(params)).to match_array []
        end

        it "searches all subfields of 'aggregatedCHO.date'" do
          name = 'aggregatedCHO.date'
          field = stub(:name => name, :geo_point? => false, :subfields? => true)
          V1::Schema.stub(:field).with('item', name) { field }
          params = {name => '1999-08-07'}
          expect(subject.field_queries(params))
            .to match_array(
                            
                            [['1999-08-07', {'fields' => ['aggregatedCHO.date.*'],'lenient' => true }]]
                            )
        end

        it "handles an empty search correctly" do
          params = {}
          expect(subject.field_queries(params)).to match_array []
        end
      end

      describe "#date_range_queries" do
        it "handles closed date ranges (aka 'between')" do
          params = {'temporal.after' => '1980', 'temporal.before' => '1990'}
          expect(subject.date_range_queries(params))
            .to match_array [
                             ["temporal.end", {:gte => "1980", :lt => '9999'}],
                             ["temporal.begin", {:lte => "1990", :gt => '-9999'}]
                            ]
        end

        it "handles begin-only date ranges" do
          params = {'temporal.after' => '1980'}
          expect(subject.date_range_queries(params))
            .to match_array [["temporal.end", {:gte => "1980", :lt => '9999'}]]
        end

        it "handles end-only date ranges" do
          params = {'temporal.before' => '1990'}
          expect(subject.date_range_queries(params))
            .to match_array [["temporal.begin", {:lte => "1990", :gt => '-9999'}]]
        end

        it "returns an empty array when no date range params exist" do
          params = {'q' => 'banana'}
          expect(subject.date_range_queries(params)).to eq []
        end
      end

    end

  end

end

