require 'v1/item'

module Rails; end

module V1

  describe Item do

    before(:each) do
      stub_const("V1::Config::SEARCH_INDEX", "some_index")
      Rails.stub_chain(:logger, :debug) { stub }
    end

    describe Item::SEARCH_OPTION_FIELDS do
      it "contains the expected values" do
        expect(Item::SEARCH_OPTION_FIELDS).to match_array %w( fields page_size offset )
      end
    end

    describe "#searchable_field?" do
      before(:each) do
        stub_const("V1::Item::SEARCHABLE_FIELDS", %w( title created ))
      end

      it "detects regular searchable fields as searchable" do
        expect(subject.searchable_field?('title')).to be_true
      end
      
      it "detects .start and .end variations of a searchable field as searchable" do
        expect(subject.searchable_field?('created.start')).to be_true
        expect(subject.searchable_field?('created.end')).to be_true
      end
      
      it "rejects unknown fields" do
        expect(subject.searchable_field?('action')).to be_false
      end
    end

    describe "#fetch" do
      it "delegates to V1::Repository.fetch" do
        repo_item_stub = stub
        V1::Repository.should_receive(:fetch).with(2) { repo_item_stub }
        expect(subject.fetch(2)).to eq repo_item_stub
      end
    end

    describe "#date_range_query_string" do
      #    def self.date_range_query_string(base_name, value, params)

      it "handles closed date ranges" do
        params = {'created.start' => '2012-01-01', 'created.end' => '2012-01-31'}
        expect(
               subject.date_range_query_string('created', params)
               ).to eq 'created:[2012-01-01 TO 2012-01-31]'
      end
      
      it "handles begin-only date ranges" do
        params = {'created.start' => '2012-01-01'}
        expect(
               subject.date_range_query_string('created', params)
               ).to eq 'created:[2012-01-01 TO *]'
      end
      it "handles end-only date ranges" do
        params = {'created.end' => '2012-01-31'};
        expect(
               subject.date_range_query_string('created', params)
               ).to eq 'created:[* TO 2012-01-31]'
      end
    end

    describe "#build_query_strings" do
      it "returns correct query string for a free text search" do
        params = {'q' => 'something'}
        expect(subject.build_query_strings(params)).to match_array ['something']
      end
      
      it "returns correct query string for field search" do
        params = {'title' => 'some title'}
        expect(subject.build_query_strings(params)).to match_array ['title:some title']
      end

      it "ignores query options fields" do
        params = {'title' => 'some title', 'page_size' => 2}
        expect(subject.build_query_strings(params)).to match_array ['title:some title']
      end

      it "handles an empty search correctly" do
        params = {}
        expect(subject.build_query_strings(params)).to match_array []
      end

    end

    describe "#build_query_booleans" do
      it "should set up proper 'boolean.must' blocks for each search field" do
        params = {'title' => 'title1'  , 'description' => 'description2'}
        subject.should_receive(:build_query_strings).with(params) { ['titleQueryString', 'descriptionQueryString'] }
        mock_boolean = mock('boolean')
        subject.should_receive(:lambda).twice.and_yield(mock_boolean)

        mock_must = mock('must')
        mock_boolean.should_receive(:must).twice.and_yield(mock_must)

        mock_must.should_receive(:string).with('titleQueryString')
        mock_must.should_receive(:string).with('descriptionQueryString')
        subject.build_query_booleans(params)
      end
    end

    describe "#search" do
      let(:search) { mock('search').as_null_object }

      it "uses V1::Config::SEARCH_INDEX for its search index" do
        params = {'q' => 'banana'}
        Tire::Search::Search.should_receive(:new).with(V1::Config::SEARCH_INDEX) { search }
        subject.search(params)
      end

      context "when there are no search params" do
        it "should not call search.query"
        it "should return global facets?"
      end        

      it "returns search.results()" do
        params = {'q' => 'banana'}
        Tire::Search::Search.stub(:new) { search }
        search.stub(:query) { stub }

        results = stub("results", :size => 1)
        search.should_receive(:results) { results }

        expect(subject.search(params)).to eq results
      end

    end

  end

end
