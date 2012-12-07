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

      describe "#build_date_range_queries" do
        # ["[2012-01-01 TO 2012-01-31]", {"fields"=>["created"]}]
        it "handles closed date ranges" do
          params = {'created.after' => '2012-01-01', 'created.before' => '2012-01-31'}
          expect(
                 subject.build_date_range_queries('created', params)
                 ).to match_array ['[2012-01-01 TO 2012-01-31]', {'fields'=>['created']}]
        end
        
        it "handles begin-only date ranges" do
          params = {'created.after' => '2012-01-01'}
          expect(
                 subject.build_date_range_queries('created', params)
                 ).to match_array ['[2012-01-01 TO *]', {'fields' => ['created']}]
        end
        it "handles end-only date ranges" do
          params = {'created.before' => '2012-01-31'};
          expect(
                 subject.build_date_range_queries('created', params)
                 ).to match_array ['[* TO 2012-01-31]', {'fields' => ['created']}]

        end
      end

      describe "#field_queries" do
        it "returns correct query string for a free text search" do
          params = {'q' => 'something'}
          expect(subject.field_queries(params)).to match_array [['something']]
        end
        
        it "returns correct query string for field search" do
          params = {'title' => 'some title'}
          expect(subject.field_queries(params)).to match_array [['some title', {'fields' => ['title']}]]
        end

        it "ignores unknown query params" do
          params = {'title' => 'some title', 'page_size' => 2}
          expect(subject.field_queries(params)).to match_array [['some title', {'fields' => ['title']}]]
        end

        it "handles 'spatial.state' as a normal field search" do
          params = {'spatial.state' => 'MA'}
          expect(subject.field_queries(params)).to match_array [['MA', {'fields' => ['spatial.state']}]]
        end

        it "handles 'created' as a normal field search" do
          params = {'created' => '1999-08-07'}
          expect(subject.field_queries(params)).to match_array [['1999-08-07', {'fields' => ['created']}]]
        end

        it "delegates 'created.after' search to build_date_range_queries instead of normal field search" do
          params = {'created.after' => '1999-08-07'}
          subject.should_receive(:build_date_range_queries) { ['delegated'] }
          expect(subject.field_queries(params)).to match_array [['delegated']]
        end

        it "handles an empty search correctly" do
          params = {}
          expect(subject.field_queries(params)).to match_array []
        end
      end

      describe "#temporal_queries" do
        it "returns an empty array when no temporal range params exist"
        it "returns correct range data for temporal.before"
        it "returns correct range data for temporal.before and temporal.after in same query"
      end

    end

  end

end

