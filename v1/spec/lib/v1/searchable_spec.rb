require 'v1/searchable'

#module Rails; end

# create fake 'searchable' resource
module SearchableItem
  extend V1::Searchable
end

module V1

  module Searchable 

    describe Searchable do

      before(:each) do
        stub_const("V1::Config::SEARCH_INDEX", "some_index")
        #Rails.stub_chain(:logger, :debug) { stub }
        subject.stub(:verbose_debug)
      end

      context "Module constants" do
        describe DEFAULT_SORT_ORDER do
          it "has the correct value" do
            expect(DEFAULT_SORT_ORDER).to eq "asc"
          end
        end

        describe "DEFAULT_PAGE_SIZE" do
          it "has the correct value" do
            expect(DEFAULT_PAGE_SIZE).to eq 10
          end
        end
        
        describe DEFAULT_MAX_PAGE_SIZE do
          it "has the correct value" do
            expect(DEFAULT_MAX_PAGE_SIZE).to eq 100
          end
        end

      end
    end
  end

  describe SearchableItem do

    describe "#fetch" do
      it "delegates to V1::Repository.fetch" do
        repo_item_stub = stub
        V1::Repository.should_receive(:fetch).with(2) { repo_item_stub }
        expect(subject.fetch(2)).to eq repo_item_stub
      end

      it "can accept more than one item" do
        #BARRETT: This test is a little confused and verbose
        repo_item_stub_1 = stub
        repo_item_stub_2 = stub
        V1::Repository.should_receive(:fetch).with(["2","3"]) { [repo_item_stub_1, repo_item_stub_1] }
        expect(subject.fetch(["2","3"])).to eq [repo_item_stub_1, repo_item_stub_1]
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
        ).to eq ['title', Searchable::DEFAULT_SORT_ORDER]
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
        ).to eq ['title', Searchable::DEFAULT_SORT_ORDER]
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
        expect(subject.get_search_size(params)).to eq(Searchable::DEFAULT_PAGE_SIZE)
      end

      it "returns the desired page size when a valid integer param is passed" do
        params = { "page_size" => "20" }
        expect(subject.get_search_size(params)).to eq (20)
      end

      it "returns the default page size when no search size param is passed" do
        params = {}
        expect(subject.get_search_size(params)).to eq (Searchable::DEFAULT_PAGE_SIZE)
      end

      it "returns the default max page size when the search size is greater than the max" do
        huge_size = Searchable::DEFAULT_MAX_PAGE_SIZE + 1
        params = { "page_size" => huge_size }
        expect(subject.get_search_size(params)).to eq (Searchable::DEFAULT_MAX_PAGE_SIZE)
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

      before(:each) do
        Tire.stub(:search).and_yield(mock_search)
      end

      it "uses V1::Config::SEARCH_INDEX for its search index" do
        params = {'q' => 'banana'}
        Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX).and_yield(mock_search)
        subject.should_receive(:build_dictionary_wrapper)
        subject.search(params)
      end

      it "builds facets if it receives a facets param" do
        params = {'q' => 'banana', 'facets' => 'title'}

        subject.stub(:build_dictionary_wrapper)
        V1::Searchable::Facet.should_receive(:build_all).with(mock_search, anything)
        subject.search(params)
      end

      it "returns search.results() with dictionary wrapper" do
        params = {'q' => 'banana'}
        results = stub("results")
        dictionary_results = stub("dictionary_wrapped")
        mock_search.stub(:results) { results }
        subject.stub(:build_dictionary_wrapper).with(mock_search) { dictionary_results }
        expect(subject.search(params)).to eq dictionary_results
      end

      context "sorting" do
        it "sorts by field name if present" do
          params = {'q' => 'banana',  'sort_by' => 'title' }
          mock_search.should_receive(:sort)
          subject.should_receive(:build_dictionary_wrapper)
          subject.search(params)
        end

        it "does not implement custom sorting when no sort params present" do
          params = {'q' => 'banana'}
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
