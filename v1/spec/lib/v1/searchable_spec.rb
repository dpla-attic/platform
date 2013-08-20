require 'v1/searchable'

module V1

  module SearchableItem
    extend Searchable
    def self.resource; 'test_resource'; end
  end

  module Searchable 

    describe Searchable do

      before(:each) do
        subject.stub(:verbose_debug)
      end

      context "Module constants" do
        it "DEFAULT_PAGE_SIZE has the correct value" do
          expect(DEFAULT_PAGE_SIZE).to eq 10
        end
        
        it "MAX_PAGE_SIZE has the correct value" do
          expect(MAX_PAGE_SIZE).to eq 500
        end

        it "BASE_QUERY_PARAMS has the correct value" do
          expect(BASE_QUERY_PARAMS).to match_array %w( 
              q controller action sort_by sort_by_pin sort_order page page_size facets facet_size filter_facets fields callback _ x
            )
        end

      end
    end
  end

  describe SearchableItem do
    let(:resource) { 'test_resource' }
    
    describe "#validate_query_params" do
      before(:each) do
        stub_const("Searchable::BASE_QUERY_PARAMS", %w( q controller action ) )
      end
      it "compares against both BASE_QUERY_PARAMS and queryable_field_names" do
        Schema.stub(:queryable_field_names).with(resource) { %w( title description ) }

        expect {
          subject.validate_query_params({'q' => 'banana', 'title' => 'curious george'})
        }.not_to raise_error

        expect {
          subject.validate_query_params({'invalid_field' => 'banana'})
        }.to raise_error BadRequestSearchError, /invalid field/i
      end
    end

    describe "#id_to_private_id" do
      it "calls search correctly when called with a single id" do
        subject.should_receive(:search).with({ 'id' => 'aaa' }) {
          { 'docs' => [{"_id" => "A", "id" => "aaa"}] }
        }
        expect(subject.id_to_private_id(['aaa'])).to eq( {'aaa' => 'A'} )
      end
      it "calls search correctly when called with multiple ids" do
        subject.should_receive(:search).with({ 'id' => 'aaa OR bbb' }) {
          { 'docs' => [{"_id" => "A", "id" => "aaa"}, {"_id" => "B", "id" => "bbb"}] }
        }
        expect(subject.id_to_private_id(['aaa', 'bbb'])).to eq( {'aaa' => 'A', 'bbb' => 'B'} )
      end
    end

    describe "#fetch" do
      let(:pub_a) { 'aaa' }
      let(:priv_a) { 'A' }
      let(:pub_b) { 'bbb' }
      let(:priv_b) { 'B' }
      let(:pub_c) { 'ccc' }

      let(:fetch_result1) {
        { "count" => 1, "docs" => [{"_id" => "A", "id" => "aaa"}] }
      }
      let(:fetch_result2) {
        { "count" => 1, "docs" => [{"_id" => "B", "id" => "bbb"}] }
      }
      let(:result_ab) {
        { "count" => 2, "docs" => [{"_id" => "A", "id" => "aaa"}, {"_id" => "B", "id" => "bbb"}] }
      }
      let(:missing_stub){
        { "id" => "ccc", "error" => "404" }
      }

       it "delegates transformed ids to Repository.fetch" do
        subject.should_receive(:id_to_private_id).with( [pub_a] ) { {pub_a => priv_a} }
        Repository.should_receive(:fetch).with([priv_a]) { fetch_result1 }
        expect(subject.fetch([pub_a])).to eq fetch_result1 
      end

      it "handles a fetch for an array of multiple IDs" do
        subject.stub(:id_to_private_id).with( [pub_a, pub_b] ) { {pub_a => priv_a, pub_b => priv_b} }
        Repository.should_receive(:fetch).with([priv_a, priv_b]) { result_ab }
        expect(subject.fetch([pub_a, pub_b])).to eq result_ab
      end

      it "handles a fetch for a string containing multiple IDs" do
        subject.stub(:id_to_private_id).with( [pub_a, pub_b] ) { {pub_a => priv_a, pub_b => priv_b} }
        Repository.stub(:fetch).with([priv_a, priv_b]) { result_ab }
        expect(subject.fetch("aaa,bbb")).to eq result_ab
      end

      it "handles partial search miss" do
        subject.stub(:id_to_private_id).with( [pub_a, pub_c] ) { {pub_a => priv_a} }
        Repository.should_receive(:fetch).with([priv_a]) { fetch_result1 }
        expect(subject.fetch([pub_a, pub_c]))
          .to eq({
                   "count" => 2,
                   "docs" => [{"_id" => "A", "id" => "aaa"}, { "id" => "ccc", "error" => "404" }]
                 })
      end

      it "raises error on search miss on 1 of 1 IDs" do
        subject.stub(:id_to_private_id) { {} }
        expect {
          subject.fetch(["non-existent-ID"])
        }.to raise_error(NotFoundSearchError)
      end

    end

    describe "#validate_field_params" do
      it "raises BadRequestSearchError if invalid field was sent" do
        Schema.stub(:queryable_field_names).with(resource) { %w( title ) }
        params = {'fields' => 'some_invalid_field'}
        expect  { 
          subject.validate_field_params(params) 
        }.to raise_error BadRequestSearchError, /fields parameter/
      end
      it "does not raise an error when all fields are valid" do
        Schema.stub(:queryable_field_names).with(resource) { %w( title description ) }
        params = {'fields' => 'title,description'}
        expect {
          subject.validate_field_params(params)
        }.not_to raise_error
      end
      it "does not raise an error when no fields are specified" do
        Schema.stub(:queryable_field_names).with(resource) { %w( title description ) }
        params = {}
        expect {
          subject.validate_field_params(params)
        }.not_to raise_error
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
        huge_size = Searchable::MAX_PAGE_SIZE + 1
        params = { "page_size" => huge_size }
        expect(subject.search_page_size(params)).to eq (Searchable::MAX_PAGE_SIZE)
      end

      it "supports page_size=0" do
        params = { "page_size" => 0 }
        expect(subject.search_page_size(params)).to eq 0
      end
    end

    describe "#wrap_results" do
      it "wraps results set correctly" do
        results = double("results", :total => 10, :facets => nil)
        search = double("search", :results => results, :options => {:from => 0, :size => 10})
        formatted_results = double
        facets = double
        
        subject.stub(:format_results) { formatted_results }
        subject.stub(:format_facets) { facets }
        params = double
        subject.stub(:get_facet_size)

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
          "date.begin.year" => {
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
          "date.begin.century" => {
            "_type"=>"range",
            "ranges"=> [
                        {"from"=>946684800000.0,
                          "from_str"=>"2000",
                          "to"=>4102444800000.0,
                          "to_str"=>"2100",
                          "count"=>1,
                          "min"=>959817600000.0,
                          "max"=>959817600000.0,
                          "total_count"=>1,
                          "total"=>959817600000.0,
                          "mean"=>959817600000.0},
                        {"from"=>-2208988800000.0,
                          "from_str"=>"1900",
                          "to"=>946684800000.0,
                          "to_str"=>"2000",
                          "count"=>9,
                          "min"=>104025600000.0,
                          "max"=>378691200000.0,
                          "total_count"=>9,
                          "total"=>2818022400000.0,
                          "mean"=>313113600000.0}
                       ]
          },
          "date.begin.decade" => {
            "_type"=>"range",
            "ranges"=> [
                        {"from"=>0.0,
                          "from_str"=>"1970",
                          "to"=>315532800000.0,
                          "to_str"=>"1980",
                          "count"=>3,
                          "min"=>104025600000.0,
                          "max"=>252460800000.0,
                          "total_count"=>3,
                          "total"=>577411200000.0,
                          "mean"=>192470400000.0},
                        {"from"=>315532800000.0,
                          "from_str"=>"1980",
                          "to"=>631152000000.0,
                          "to_str"=>"1990",
                          "count"=>6,
                          "min"=>347155200000.0,
                          "max"=>378691200000.0,
                          "total_count"=>6,
                          "total"=>2240611200000.0,
                          "mean"=>373435200000.0},
                        {"from"=>631152000000.0,
                          "from_str"=>"1990",
                          "to"=>946684800000.0,
                          "to_str"=>"2000",
                          "count"=>0,
                          "total_count"=>0,
                          "total"=>0.0,
                          "mean"=>0.0}
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
        expect(subject.format_facets(facets, nil)['date.begin.year']['entries'])
          .to eq([{"time"=>"2000", "count"=>2}, {"time"=>"1975", "count"=>1}])
      end
      
      it "identifies date facets with century interval as _type: 'date_histogram'" do
        expect(subject.format_facets(facets, nil)['date.begin.century']['_type'])
          .to eq 'date_histogram'
      end

      it "formats and sorts date facets with century interval like native date_histogram facets" do
        expect(subject.format_facets(facets, nil)['date.begin.century']['entries'])
          .to eq([{"time"=>"1900", "count"=>9}, {"time"=>"2000", "count"=>1}])
      end

      it "formats and sorts date facets with decade interval like native date_histogram facets" do
        expect(subject.format_facets(facets, nil)['date.begin.decade']['entries'])
          .to eq([{"time"=>"1980", "count"=>6}, {"time"=>"1970", "count"=>3}])
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
      let(:date_in_milli) { 946702800000 }

      it "defaults to YYYY-MM-DD" do
        expect(subject.format_date_facet(date_in_milli)).to eq '2000-01-01'
      end

      it "formats day facets correctly" do
        expect(subject.format_date_facet(date_in_milli, 'day')).to eq '2000-01-01'
      end
        
      it "formats month facets correctly" do
        expect(subject.format_date_facet(date_in_milli, 'month')).to eq '2000-01'
      end
        
      it "formats year facets correctly" do
        expect(subject.format_date_facet(date_in_milli, 'year')).to eq '2000'
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

    describe "#get_facet_size" do
      it "delegates to Facet module" do
        params = double
        facet_size = double
        Searchable::FacetOptions.should_receive(:facet_size).with(params) { facet_size }
        expect(subject.get_facet_size(params)).to eq facet_size
      end
    end

    describe "#build_queries" do
      it "calls query, filter (but not facet) build_all methods with correct params" do
        search = double
        params = {'q' => 'banana'}
        Searchable::Query.should_receive(:build_all).with(resource, search, params) { true }
        Searchable::Filter.should_receive(:build_all).with(resource, search, params) { false }
        Searchable::Facet.should_not_receive(:build_all)
        subject.build_queries(resource, search, params)
      end
    end

    describe "#search" do
      let(:mock_search) { double('mock_search').as_null_object }

      before(:each) do
        Tire.stub(:search).and_yield(mock_search)
        subject.stub(:wrap_results)
        subject.stub(:validate_query_params)
        subject.stub(:validate_field_params)
        subject.stub(:build_queries)
        subject.stub(:build_facets)
      end

      it "validates params and field params" do
        params = {}
        subject.should_receive(:validate_query_params).with(params)
        subject.should_receive(:validate_field_params).with(params)
        subject.search(params)
      end

      it "restricts all searches to a resource" do
        params = {'q' => 'banana'}
        Tire.should_receive(:search).with(Config.search_index + '/' + resource)
        subject.search(params)
      end

      # it "calls build_querie with correct params" do
      #   params = {'q' => 'banana'}
      #   subject.should_receive(:build_queries).with(resource, mock_search, params)
      #   subject.search(params)
      # end

      it "returns search.results() with dictionary wrapper" do
        params = {'q' => 'banana'}
        results = double("results")
        dictionary_results = double("dictionary_wrapped")
        mock_search.stub(:results) { results }
        subject.stub(:wrap_results).with(mock_search, params) { dictionary_results }
        expect(subject.search(params)).to eq dictionary_results
      end

      it "limits the requested fields if fields param is present" do
        params = {'fields' => 'title,type'}
        mock_search.should_receive(:fields).with( %w( title type ) )
        subject.search(params)
      end

    end

  end

end
