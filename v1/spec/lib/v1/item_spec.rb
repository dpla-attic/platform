require 'v1/item'

module Rails; end

module V1

  describe Item do

    before(:each) do
      stub_const("V1::Config::SEARCH_INDEX", "some_index")
      Rails.stub_chain(:logger, :debug) { stub }
      subject.stub(:verbose_debug)
    end

    context "Module constants" do
      describe V1::Item::DEFAULT_SPATIAL_DISTANCE do
        it "has the correct value" do
          expect(V1::Item::DEFAULT_SPATIAL_DISTANCE).to eq '20mi'
        end
      end

      describe V1::Item::DEFAULT_SORT_ORDER do
        it "has the correct value" do
          expect(V1::Item::DEFAULT_SORT_ORDER).to eq "asc"
        end
      end

      describe V1::Item::DEFAULT_PAGE_SIZE do
        it "has the correct value" do
          expect(V1::Item::DEFAULT_PAGE_SIZE).to eq 10
        end
      end

      describe V1::Item::SEARCH_OPTION_FIELDS do
        it "has the correct values" do
          expect(V1::Item::SEARCH_OPTION_FIELDS).to match_array %w( fields page_size offset )
        end
      end
    end

    describe "#fetch" do
      it "delegates to V1::Repository.fetch" do
        repo_item_stub = stub
        V1::Repository.should_receive(:fetch).with(2) { repo_item_stub }
        expect(subject.fetch(2)).to eq repo_item_stub
      end

      it "can accept more than one item" do
        repo_item_stub_1 = stub
        repo_item_stub_2 = stub
        V1::Repository.should_receive(:fetch).with(["2","3"]) { [repo_item_stub_1, repo_item_stub_1] }
        expect(subject.fetch(["2","3"])).to eq [repo_item_stub_1, repo_item_stub_1]
      end
    end

    describe "#build_date_range_queries" do
      it "handles closed date ranges" do
        params = {'created.after' => '2012-01-01', 'created.before' => '2012-01-31'}
        expect(
               subject.build_date_range_queries('created', params)
               ).to eq 'created:[2012-01-01 TO 2012-01-31]'
      end
      
      it "handles begin-only date ranges" do
        params = {'created.after' => '2012-01-01'}
        expect(
               subject.build_date_range_queries('created', params)
               ).to eq 'created:[2012-01-01 TO *]'
      end
      it "handles end-only date ranges" do
        params = {'created.before' => '2012-01-31'};
        expect(
               subject.build_date_range_queries('created', params)
               ).to eq 'created:[* TO 2012-01-31]'
      end
    end

    describe "#build_field_query_strings" do
      it "returns correct query string for a free text search" do
        params = {'q' => 'something'}
        expect(subject.build_field_query_strings(params)).to match_array ['something']
      end
      
      it "returns correct query string for field search" do
        params = {'title' => 'some title'}
        expect(subject.build_field_query_strings(params)).to match_array ['title:some title']
      end

      it "ignores unknown query params" do
        params = {'title' => 'some title', 'page_size' => 2}
        expect(subject.build_field_query_strings(params)).to match_array ['title:some title']
      end

      it "handles 'spatial.state' as a normal field search" do
        params = {'spatial.state' => 'MA'}
        expect(subject.build_field_query_strings(params)).to match_array ['spatial.state:MA']
      end

      it "handles 'created' as a normal field search" do
        params = {'created' => '1999-08-07'}
        expect(subject.build_field_query_strings(params)).to match_array ['created:1999-08-07']
      end

      it "delegates 'created.after' search to build_date_range_queries instead of normal field search" do
        params = {'created.after' => '1999-08-07'}
        subject.should_receive(:build_date_range_queries) { 'delegated' }
        expect(subject.build_field_query_strings(params)).to match_array ['delegated']
      end

      it "handles an empty search correctly" do
        params = {}
        expect(subject.build_field_query_strings(params)).to match_array []
      end
    end

    describe "#build_field_queries" do
      it "should set up proper 'boolean.must' blocks for each search field" do
        params = {'title' => 'title1'  , 'description' => 'description2'}
        subject.should_receive(:build_field_query_strings).with(params) { ['titleQString', 'descQString'] }
        mock_boolean = mock('boolean')
        subject.should_receive(:lambda).twice.and_yield(mock_boolean)

        mock_must = mock('must')
        mock_boolean.should_receive(:must).twice.and_yield(mock_must)

        mock_must.should_receive(:string).with('titleQString')
        mock_must.should_receive(:string).with('descQString')
        subject.build_field_queries(params)
      end
    end

    describe "#build_spatial_coordinates_query" do

      it "handles coordinate queries without a range" do
        params = {'spatial.coordinates' => "42.1,-71"}
        expect(
               subject.build_spatial_coordinates_query(params)
               ).to eq ['geo_distance', {'spatial.coordinates' => "42.1,-71", 'distance' => V1::Item::DEFAULT_SPATIAL_DISTANCE} ]
      end
      
      it "handles coordinate queries without a range" do
        params = {'spatial.coordinates' => "42.1,-71", 'spatial.distance' => '11mi'}
        expect(
               subject.build_spatial_coordinates_query(params)
               ).to eq ['geo_distance', {'spatial.coordinates' => "42.1,-71", 'distance' => '11mi'} ]
      end

      it "returns nil when there is no spatial.coordinates query" do
        params = {'q' => 'banana'}
        expect(
               subject.build_spatial_coordinates_query(params)
               ).to eq nil
      end

    end

    describe "build_sort_attributes" do
      it "returns nil when sort params are not present" do
        params = {'q' => 'banana'}
        expect(subject.build_sort_attributes(params)).to eq nil
      end

      it "returns a valid sort order if an invalid sort order param present" do
        params = {'q' => 'banana', 'sort_by' => 'title', 'sort_order' => 'apple'}
        expect(
          subject.build_sort_attributes(params)
        ).to eq ['title', V1::Item::DEFAULT_SORT_ORDER]
      end

      it "returns the valid sort order if a valid sort order is param present" do
        params = {'q' => 'banana', 'sort_by' => 'title', 'sort_order' => 'desc'}
        expect(
          subject.build_sort_attributes(params)
        ).to eq ['title', 'desc']
      end

      it "returns a valid sort order param if no sort order param present" do
        params = {'q' => 'banana', 'sort_by' => 'title'}
        expect(
          subject.build_sort_attributes(params)
        ).to eq ['title', V1::Item::DEFAULT_SORT_ORDER]
      end
    end

    describe "#build_all_queries" do

      it "returns field, temporal, created(range) queries as flattened array" do
        subject.stub(:build_field_queries) { [:fq1, :fq2] }
        subject.stub(:build_temporal_query) { [:tq1, :tq2] }
        expect(subject.build_all_queries({})).to match_array [:fq1, :fq2, :tq1, :tq2]
      end
    end

    describe "#get_search_starting_point" do
      it "returns starting point based on 'page size' and the start page" do
        params = { "page" => "2", 'page_size' => "5" }
        expect(subject.get_search_starting_point(params)).to eq (5)
      end

      it "returns the starting point of 0 when called with non-integer param" do
        params = { "page" => "a" }
        expect(subject.get_search_starting_point(params)).to eq (0)
      end

      it "returns the starting point of zero when called with no  page param" do 
        params = {}
        expect(subject.get_search_starting_point(params)).to eq (0)
      end
    end

    describe "#get_search_size" do
      it "returns the default page size when a non-integer param is passed" do
        params = { "page_size" => "a" }
        expect(subject.get_search_size(params)).to eq(V1::Item::DEFAULT_PAGE_SIZE)
      end

      it "returns the desired page size when a valid integer param is passed" do
        params = { "page_size" => "20" }
        expect(subject.get_search_size(params)).to eq (20)
      end

      it "returns the default page size when no search size param is passed" do
        params = {}
        expect(subject.get_search_size(params)).to eq (V1::Item::DEFAULT_PAGE_SIZE)
      end
    end

#    describe "#build_dictionary_wrapper" do
#      it "returns a wrapper around documents" do
#        searcher = stub "searcher"
#        searcher_response = stub "response"
#        searcher.stub(:options) { {:from => 0, :size => 10} }
#        searcher.stub_chain(:response, :body, :as_json) { "{'hits': { 'total': 10, 'hits': [{'id': 1}, {'id': 2}] }}" }
#        
#        expect(subject.build_dictionary_wrapper(searcher)).to eq(
#          {
#            'count' => 10,
#            'limit' => 10,
#            'start' => 0,
#            'docs' => [{'id' => 1}, {'id' => 2}]
#          } 
#        )
#      end
#    end

    describe "#reformat_result_documents" do
      it "remaps elasticsearch item wrapper to collapse items to first level with score" do
        docs = [{"_score" => 1, "_source" => {
          "_id" => "1",
          "title" => "banana one",
          "description" => "description one",
          "dplaContributor" => nil,
          "collection" => "",
          "creator" => "",
          "publisher" => "",
          "created" => "1950-01-01",
          "type" => "", 
          "format" => "",
          "rights" => "",
          "relation" => "",
          "source" => "",
          "contributor" => "",
          "_type" => "item"}}]
        expect(subject.reformat_result_documents(docs)).to eq(
          [{
          "_id" => "1",
          "title" => "banana one",
          "description" => "description one",
          "dplaContributor" => nil,
          "collection" => "",
          "creator" => "",
          "publisher" => "",
          "created" => "1950-01-01",
          "type" => "",
          "format" => "",
          "rights" => "",
          "relation" => "",
          "source" => "",
          "contributor" => "",
          "_type" => "item",
          "score" => 1 }]
        )
      end
    end

    describe "#search" do
      let(:mock_search) { mock('mock_search').as_null_object }

      it "uses V1::Config::SEARCH_INDEX for its search index" do
        params = {'q' => 'banana'}
        Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX).and_yield(mock_search)
        subject.should_receive(:build_dictionary_wrapper)
        subject.search(params)
      end

      it "returns search.results() with dictionary wrapper" do
        params = {'q' => 'banana'}
        Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX).and_yield(mock_search)

        results = stub("results")
        dictionary_results = stub("dictionary_wrapped")
        mock_search.stub(:results) { results }
        subject.stub(:build_dictionary_wrapper).with(mock_search) { dictionary_results }
        expect(subject.search(params)).to eq dictionary_results
      end

      it "filters on a spatial query if present" do
        params = {'spatial.coordinates' => "42.1,-71"}
        Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX).and_yield(mock_search)
        subject.stub(:build_spatial_coordinates_query) { [:test1, :test2] }
        subject.should_receive(:build_dictionary_wrapper)
        mock_search.should_receive(:filter).with( *[:test1, :test2] )
        subject.search(params) 
      end

      it "does not filter on a spatial query if it is not present" do
        params = {'q' => 'banana'}
        Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX).and_yield(mock_search)

        mock_search.should_not_receive(:filter)
        subject.should_receive(:build_dictionary_wrapper)
        subject.search(params)
      end

      context "sorting" do
        it "sorts by field name if present" do
          params = {'q' => 'banana',  'sort_by' => 'title' }
          Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX).and_yield(mock_search)
          mock_search.should_receive(:sort)
          subject.should_receive(:build_dictionary_wrapper)
          subject.search(params)
        end

        it "does not implement custom sorting when no sort params present" do
          params = {'q' => 'banana'}
          Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX).and_yield(mock_search)
          mock_search.should_not_receive(:sort)
          subject.should_receive(:build_dictionary_wrapper)
          subject.search(params)
        end
      end

      context "when there are no search params" do
        it "should not call search.query?"
        it "should return global facets?"
      end        

    end

  end

end
