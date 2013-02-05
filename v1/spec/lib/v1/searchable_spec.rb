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
        it "DEFAULT_PAGE_SIZE has the correct value" do
          expect(DEFAULT_PAGE_SIZE).to eq 10
        end
        
        it "DEFAULT_MAX_PAGE_SIZE has the correct value" do
          expect(DEFAULT_MAX_PAGE_SIZE).to eq 100
        end

        it "DEFAULT_SORT_ORDER has the correct value" do
          expect(DEFAULT_SORT_ORDER).to eq "asc"
        end

        it "BASE_QUERY_PARAMS has the correct value" do
          expect(BASE_QUERY_PARAMS).to match_array %w( 
              q controller action sort_by sort_by_pin sort_order page page_size facets facet_size fields callback
            )
        end
      end
    end
  end

  describe SearchableItem do

    describe "#validate_query_params" do
      before(:each) do
        stub_const("V1::Searchable::BASE_QUERY_PARAMS", %w( q controller action ) )
      end
      it "compares against both BASE_QUERY_PARAMS and queryable_fields" do
        Schema.stub(:queryable_fields) { %w( title description ) }

        expect {
          SearchableItem.validate_query_params({'q' => 'banana'})
          SearchableItem.validate_query_params({'title' => 'curious george'})
        }.not_to raise_error BadRequestSearchError

        expect {
          SearchableItem.validate_query_params({'invalid_field' => 'banana'})
        }.to raise_error BadRequestSearchError, /invalid field/i
      end
    end

    describe "#fetch" do
      let(:result1) {
        {
          "count" => 1,
          "docs" => [{"_id" => "1"}]
        }
      }
      let(:result2) {
        {
          "count" => 1,
          "docs" => [{"_id" => "2"}]
        }
      }
      let(:error_stub){
        {
          "id" => "ccc",
          "error" => "404"
        }
      }
 
      it "delegates transformed ids to V1::Repository.fetch" do
        subject.should_receive(:search).with({"id" => "aaa" }) { result1 }
        V1::Repository.should_receive(:fetch).with(["1"]) # { repo_item_stub }
        subject.fetch(["aaa"])
      end

      it "accepts more than one item" do
        subject.stub(:search).twice.and_return(result1, result2)
        V1::Repository.should_receive(:fetch).with(["1", "2"])
        subject.fetch(["aaa", "bbb"])
      end

      it "can handle an item that does not exist" do
        repo_item_stub_1 = stub
        subject.stub(:search).twice.and_return(result1, {'count' => 0})
        V1::Repository.should_receive(:fetch).with(["1"]) { {'docs' => [repo_item_stub_1]} }
        expect(subject.fetch(["aaa", "ccc"])['docs']).to match_array( [repo_item_stub_1, error_stub] )
      end

      it "raises error when single item not found" do
        subject.stub(:search) { {'count' => 0} }
        expect { subject.fetch(["non-existent-ID"]) }.to raise_error(NotFoundSearchError)
      end

    end

    describe "build_sort_attributes" do
      it "returns nil when sort params are not present" do
        params = {}
        expect(subject.build_sort_attributes(params)).to eq nil
      end

      it "returns a valid sort order if a valid sort order is param present" do
        params = {'sort_by' => 'id', 'sort_order' => 'desc'}
        expect(
               subject.build_sort_attributes(params)
               ).to eq [ {'id' => 'desc'} ]
      end

      it "returns a valid sort order if an invalid sort order param present" do
        params = {'sort_by' => 'id', 'sort_order' => 'apple'}
        expect(
               subject.build_sort_attributes(params)
               ).to eq [ {'id' => Searchable::DEFAULT_SORT_ORDER} ]
      end

      it "returns a valid sort order param if no sort order param present" do
        params = {'sort_by' => 'id'}
        expect(
               subject.build_sort_attributes(params)
               ).to eq [ {'id' => Searchable::DEFAULT_SORT_ORDER} ]
      end

      it "returns the valid sort_by if a valid sort order is param present" do
        params = {'sort_by' => 'id', 'sort_order' => 'asc'}
        expect(
               subject.build_sort_attributes(params)
               ).to eq [ {'id' => 'asc'} ]
      end

      it "returns correct array values for geo_point types" do
        params = {'sort_by' => 'coordinates', 'sort_by_pin' => '41,-71', 'order' => 'asc'}
        field = stub(:sort => 'geo_distance', :sortable? => true, :name => 'coordinates')
        V1::Schema.stub(:flapping) { field }
        expect(
               subject.build_sort_attributes(params)
               ).to eq [ {'_geo_distance' => { 'coordinates' => '41,-71', 'order' => 'asc' } } ]
      end

      it "returns correct array for script sort" do
        params = {'sort_by' => 'title'}
        field = stub(:sort => 'script', :sortable? => true, :name => 'title')
        V1::Schema.stub(:flapping) { field }
        expect(
               subject.build_sort_attributes(params)
               ).to eq( 
                       [{
                          '_script' => {
                            'script' => "s='';foreach(val : doc['title'].values) {s += val + ' '} s",
                            'type' => "string",
                            'order' => 'asc'
                          }
                        }]
                       )

      end

      it "raises a BadRequestSearchError on an invalid sort_by param" do
        params = {'sort_by' => 'some_invalid_field'}
        expect  { 
          subject.build_sort_attributes(params)
        }.to raise_error BadRequestSearchError, /invalid field.* sort_by parameter: some_invalid_field/i
      end

      it "raises a BadRequestSearchError on a non-sortable sort_by param" do
        params = {'sort_by' => 'some_analyzed_field'}
        V1::Schema.stub(:flapping) { stub(:sortable? => false, :name => 'foo') }
        expect  { 
          subject.build_sort_attributes(params)
        }.to raise_error BadRequestSearchError, /non-sortable field.* sort_by parameter: some_analyzed_field/i
      end
    end

    describe "#validate_field_params" do
      it "raises BadRequestSearchError if invalid field was sent" do
        V1::Schema.stub(:queryable_fields) { %w( title ) }
        params = {'fields' => 'some_invalid_field'}
        expect  { 
          subject.validate_field_params(params) 
        }.to raise_error BadRequestSearchError, /fields parameter/
      end
      it "does not raise an error when all fields are valid" do
        V1::Schema.stub(:queryable_fields) { %w( title description ) }
        params = {'fields' => 'title,description'}
        expect {
          subject.validate_field_params(params)
        }.not_to raise_error BadRequestSearchError
      end
      it "does not raise an error when no fields are specified" do
        params = {}
        expect {
          subject.validate_field_params(params)
        }.not_to raise_error BadRequestSearchError
      end
      
    end
   
    describe "#search_offset" do
      it "returns starting point based on 'page size' and the start page" do
        params = { "page" => "2", 'page_size' => "5" }
        expect(subject.search_offset(params)).to eq (5)
      end

      it "returns the starting point of 0 when called with non-integer param" do
        params = { "page" => "a" }
        expect(subject.search_offset(params)).to eq (0)
      end

      it "returns the starting point of zero when called with no  page param" do 
        params = {}
        expect(subject.search_offset(params)).to eq (0)
      end
    end

    describe "#search_page_size" do
      it "returns the default page size when a non-integer param is passed" do
        params = { "page_size" => "a" }
        expect(subject.search_page_size(params)).to eq(Searchable::DEFAULT_PAGE_SIZE)
      end

      it "returns the desired page size when a valid integer param is passed" do
        params = { "page_size" => "20" }
        expect(subject.search_page_size(params)).to eq (20)
      end

      it "returns the default page size when no search size param is passed" do
        params = {}
        expect(subject.search_page_size(params)).to eq (Searchable::DEFAULT_PAGE_SIZE)
      end

      it "returns the default max page size when the search size is greater than the max" do
        huge_size = Searchable::DEFAULT_MAX_PAGE_SIZE + 1
        params = { "page_size" => huge_size }
        expect(subject.search_page_size(params)).to eq (Searchable::DEFAULT_MAX_PAGE_SIZE)
      end

      it "supports page_size=0" do
        params = { "page_size" => 0 }
        expect(subject.search_page_size(params)).to eq 0
      end
    end

    describe "#wrap_results" do
      it "wraps results set correctly" do
        results = stub("results", :total => 10, :facets => nil)
        search = stub("search", :results => results, :options => {:from => 0, :size => 10})
        formatted_results = stub
        facets = stub
        
        subject.stub(:format_results) { formatted_results }
        subject.stub(:format_facets) { facets }
        params = stub
        V1::Searchable::Facet.stub(:facet_size)

        expect(subject.wrap_results(search, params))
          .to eq({
                   'count' => 10,
                   'limit' => 10,
                   'start' => 0,
                   'docs' => formatted_results,
                   'facets' => facets
                 })
      end
    end

    describe "#format_facets" do
      let(:facets) {
        {
          "created.start.year" => {
            "_type" => "date_histogram",
            "entries" => [
                        {
                          "time" => 157784400000,
                          "count" => 1
                        },
                        {
                          "time" => 946702800000,
                          "count" => 2
                        }
                       ]
          },
          "subject.name" => {
            "_type" => "terms",
            "terms" => [
                      {
                        "term" => "Noodle Bar",
                        "count" => 1
                      }
                     ]
          }
        }
      }
      it "formats date facets" do
        subject.should_receive(:format_date_facet).with(157784400000, 'year')
        subject.should_receive(:format_date_facet).with(946702800000, 'year')
        subject.format_facets(facets, nil)
      end
      it "sorts the date_histogram facet by count descending, by default" do
        expect(subject.format_facets(facets, nil)['created.start.year']['entries'])
          .to eq([{"time"=>"2000", "count"=>2}, {"time"=>"1975", "count"=>1}])
      end
      it "enforces facet_size limit" do
        # returned facets should all have 1 value hash in them
        formatted = subject.format_facets(facets, 1)
        
        formatted.each do |name, payload|
          facet_values = payload['entries'] || payload['terms']
          expect(facet_values.size).to be <= 1
        end

      end
    end

    describe "#format_date_facet" do
      let(:epoch) { 946702800000 }

      it "defaults to YYYY-MM-DD" do
        expect(subject.format_date_facet(epoch)).to eq '2000-01-01'
      end

      it "formats day facets correctly" do
        expect(subject.format_date_facet(epoch, 'day')).to eq '2000-01-01'
      end
        
      it "formats month facets correctly" do
        expect(subject.format_date_facet(epoch, 'month')).to eq '2000-01'
      end
        
      it "formats year facets correctly" do
        expect(subject.format_date_facet(epoch, 'year')).to eq '2000'
      end
        
      it "formats decade facets correctly" do
        date1993 = Date.new(1993,1,1).to_time.to_i * 1000
        expect(subject.format_date_facet(date1993, 'decade')).to eq '1990'
      end
        
      it "formats century facets correctly" do
        date1993 = Date.new(1993,1,1).to_time.to_i * 1000
        expect(subject.format_date_facet(date1993, 'century')).to eq '1900'
      end

      it "returns input value unchanged when interval is not recognized" do
        date1993 = Date.new(1993,1,1).to_time.to_i * 1000
        expect(subject.format_date_facet(date1993, 'fake-interval')).to eq '1993-01-01'
      end

    end

    describe "#format_results" do
      it "reformats results correctly" do
        docs = [{
          "_score" => 1, 
          "_source" => {
            "_id" => "1",
            "_type" => "1",
            "title" => "banana",
            "description" => "desc"
          }
        }]
        expect(subject.format_results(docs)).to match_array(
          [{
             "_id" => "1",
             "title" => "banana",
             "description" => "desc",
             "score" => 1
           }]
        )
      end

      it "reformats results correctly for a field-limited query" do
        docs = [{
          "_index" => "dpla",
          "_type" => "item",
          "_id" => "1",
          "_score" => 1.0,
          "fields" => {"title" => "banana"}
        }]
        expect(subject.format_results(docs)).to match_array(
          [{"title" => "banana"}]
        )
      end

      it "reformats results correctly for a field-limited query when the results are missing the requested fields" do
        docs = [{
          "_index" => "dpla",
          "_type" => "item",
          "_id" => "1",
          "_score" => 1.0
        }]
        expect(subject.format_results(docs)).to match_array(
          [{}]
        )
      end

    end

    describe "#search" do
      let(:mock_search) { mock('mock_search').as_null_object }

      before(:each) do
        Tire.stub(:search).and_yield(mock_search)
        subject.stub(:wrap_results)
      end

      it "validates params and field params" do
        params = {}
        subject.should_receive(:validate_query_params).with(params)
        subject.should_receive(:validate_field_params).with(params)
        subject.search(params)
      end

      it "uses V1::Config::SEARCH_INDEX for its search index" do
        params = {'q' => 'banana'}
        Tire.should_receive(:search).with(V1::Config::SEARCH_INDEX)
        subject.search(params)
      end

      it "calls query, filter and facet build_all methods with correct params" do
        params = {'q' => 'banana'}
        V1::Searchable::Query.should_receive(:build_all).with(mock_search, params) { true }
        V1::Searchable::Filter.should_receive(:build_all).with(mock_search, params) { false }
        V1::Searchable::Facet.should_receive(:build_all).with(mock_search, params, !true)
        subject.search(params)
      end

      it "returns search.results() with dictionary wrapper" do
        params = {'q' => 'banana'}
        results = stub("results")
        dictionary_results = stub("dictionary_wrapped")
        mock_search.stub(:results) { results }
        subject.stub(:wrap_results).with(mock_search, params) { dictionary_results }
        expect(subject.search(params)).to eq dictionary_results
      end

      context "sorting" do
        it "sorts by field name if present" do
          params = {'q' => 'banana',  'sort_by' => 'title' }
          subject.stub(:validate_query_params)
          subject.should_receive(:build_sort_attributes).with(params) { [] } 
          mock_search.should_receive(:sort)
          subject.stub(:wrap_results)
          subject.search(params)
        end

        it "does not implement custom sorting when no sort params present" do
          params = {'q' => 'banana'}
          mock_search.should_not_receive(:sort)
          subject.should_receive(:wrap_results)
          subject.search(params)
        end
      end

      it "limits the requested fields if fields param is present" do
        params = {'fields' => 'title,type'}
        subject.stub(:validate_query_params)
        subject.stub(:validate_field_params)
        mock_search.should_receive(:fields).with( %w( title type ) )
        subject.search(params)
      end

    end

  end

end
