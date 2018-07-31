require 'v1/searchable'
require 'httparty'


module V1

  module SearchableItem
    extend Searchable
    def self.resource; 'item'; end
  end

  module Searchable 

    describe Searchable do

      context "Module constants" do
        it "DEFAULT_PAGE_SIZE has the correct value" do
          expect(DEFAULT_PAGE_SIZE).to eq 10
        end
        
        it "MAX_PAGE_SIZE has the correct value" do
          expect(MAX_PAGE_SIZE).to eq 500
        end

        it "BASE_QUERY_PARAMS has the correct value" do
          expect(BASE_QUERY_PARAMS).to match_array %w( 
              q controller action sort_by sort_by_pin sort_order page page_size
              facets facet_size filter_facets fields callback _ x
              exact_field_match
            )
        end

      end
    end
  end

  describe SearchableItem do
    let(:resource) { 'item' }
    
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

    describe "#fetch" do
      let(:pub_a) { 'aaa' }
      let(:priv_a) { 'A' }
      let(:pub_b) { 'bbb' }
      let(:priv_b) { 'B' }
      let(:pub_c) { 'ccc' }

      let(:fetch_result_1doc) {
        { "count" => 1, "docs" => [{"_id" => priv_a, "id" => pub_a}] }
      }
      let(:fetch_result_nodoc) {
        { "count" => 0, "docs" => [] }
      }
      let(:result_ab) {
        { "count" => 2, "docs" => [{"_id" => priv_a, "id" => pub_a},
                                   {"_id" => priv_b, "id" => pub_b}] }
      }

      it "handles a fetch for an array of multiple IDs" do
        subject.should_receive(:search)
          .with({
            "id" => "#{pub_a} OR #{pub_b}",
            "page_size" => 50
          }) { result_ab }
        expect(subject.fetch([pub_a, pub_b])).to eq result_ab
      end

      it "handles a fetch for a string containing multiple IDs" do
        subject.should_receive(:search)
          .with({
            "id" => "#{pub_a} OR #{pub_b}",
            "page_size" => 50
          }) { result_ab }
        expect(subject.fetch("#{pub_a},#{pub_b}")).to eq result_ab
      end

      it "handles partial search miss" do
        subject.should_receive(:search)
          .with({
            "id" => "#{pub_a} OR #{pub_c}",
            "page_size" => 50
          }) { fetch_result_1doc }
        expect(subject.fetch([pub_a, pub_c]))
          .to eq({
                   "count" => 2,
                   "docs" => [{"_id" => priv_a, "id" => pub_a},
                              { "id" => pub_c, "error" => "404" }]
                 })
      end

      it "raises error on search miss on 1 of 1 IDs" do
        subject.should_receive(:search)
          .with({
            "id" => "non-existent-ID",
            "page_size" => 50
          }) { fetch_result_nodoc }
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

        result = {
          'hits' => {
            'total' => 10,
            'hits' => [],
          },
          'facets' => []
        }

        formatted_results = double
        facets = double
        
        subject.stub(:format_results) { formatted_results }
        subject.stub(:format_facets) { facets }
        params = double
        subject.stub(:get_facet_size)
        subject.stub(:search_page_size) { 10 }
        subject.stub(:search_offset) { 0 }

        expect(subject.wrap_results(result, params))
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
      # date_facets: Facets that come back in the "aggregations" property of the
      #              Elasticsearch response.
      let(:date_facets) {
        {
          "sourceResource.date.begin" => {
            "buckets" => [
              {
                "key_as_string" => "1975-01-01T00:00:00.000Z",
                "key" => 157784400000,
                "doc_count" => 1
              },
              {
                "key_as_string" => "2000-01-01T00:00:00.000Z",
                "key" => 946702800000,
                "doc_count" => 2
              }
            ]
          },
          "sourceResource.date.begin.year" => {
            "buckets" => [
              {
                "key_as_string" => "1975-01-01T00:00:00.000Z",
                "key" => 157784400000,
                "doc_count" => 1
              },
              {
                "key_as_string" => "2000-01-01T00:00:00.000Z",
                "key" => 946702800000,
                "doc_count" => 2
              }
            ]
          },
          "sourceResource.date.begin.century" => {
            "buckets" => [
                {
                    "key" => "1900-01-01T00:00:00.000Z-2000-01-01T00:00:00.000Z",
                    "from" => -2208988800000,
                    "from_as_string" => "1900-01-01T00:00:00.000Z",
                    "to" => 946684800000,
                    "to_as_string" => "2000-01-01T00:00:00.000Z",
                    "doc_count" => 9
                },
                {
                    "key" => "2000-01-01T00:00:00.000Z-2100-01-01T00:00:00.000Z",
                    "from" => 946684800000,
                    "from_as_string" => "2000-01-01T00:00:00.000Z",
                    "to" => 4102444800000,
                    "to_as_string" => "2100-01-01T00:00:00.000Z",
                    "doc_count" => 1
                }
            ]
          },
          "sourceResource.date.begin.decade" => {
            "buckets" => [
                {
                    "key" => "1970-01-01T00:00:00.000Z-1980-01-01T00:00:00.000Z",
                    "from" => 0,
                    "from_as_string" => "1970-01-01T00:00:00.000Z",
                    "to" => 315532800000,
                    "to_as_string" => "1980-01-01T00:00:00.000Z",
                    "doc_count" => 3
                },
                {
                    "key" => "1980-01-01T00:00:00.000Z-1990-01-01T00:00:00.000Z",
                    "from" => 315532800000,
                    "from_as_string" => "1980-01-01T00:00:00.000Z",
                    "to" => 631152000000,
                    "to_as_string" => "1990-01-01T00:00:00.000Z",
                    "doc_count" => 6
                },
                {   # This one should not be included because count is 0.
                    "key" => "1990-01-01T00:00:00.000Z-2000-01-01T00:00:00.000Z",
                    "from" => 631152000000,
                    "from_as_string" => "1990-01-01T00:00:00.000Z",
                    "to" => 946684800000,
                    "to_as_string" => "2000-01-01T00:00:00.000Z",
                    "doc_count" => 0
                }
            ]
          }
        }
      }

      let(:language_facets) {
        {
          "sourceResource.language.iso639_3" => {
            "doc_count_error_upper_bound" => 0,
            "sum_other_doc_count" => 0,
            "buckets" => [
                {
                    "key" => "eng",
                    "doc_count" => 292
                },
                {
                    "key" => "jpn",
                    "doc_count" => 19
                },
                {
                    "key" => "lat",
                    "doc_count" => 6
                }
            ]
          }
        }
      }

      let(:geo_facets) {
        {
          "sourceResource.spatial.coordinates" => {
            "buckets" => [
                {
                    "key" => "*-100.0",
                    "from" => 0,
                    "to" => 100,
                    "doc_count" => 0
                },
                {
                    "key" => "100.0-200.0",
                    "from" => 100,
                    "to" => 200,
                    "doc_count" => 5
                },
                {
                    "key" => "200.0-300.0",
                    "from" => 200,
                    "to" => 300,
                    "doc_count" => 4
                }
            ]
          }
        }
      }
      
      it "formats date facets" do
        subject.should_receive(:format_date_facet).with(anything(), nil).exactly(2).times
        subject.should_receive(:format_date_facet).with(anything(), 'year').exactly(2).times
        subject.should_receive(:format_date_facet).with(anything(), 'century').exactly(2).times
        subject.should_receive(:format_date_facet).with(anything(), 'decade').exactly(2).times
        subject.format_facets(date_facets, nil)
      end

      it "returns a date_histogram facet without a field modifier" do
        # Without "year", "decade", or "century"
        expect(subject.format_facets(date_facets, nil)['sourceResource.date.begin']['entries'])
          .to eq([{"time"=>"2000-01-01", "count"=>2}, {"time"=>"1975-01-01", "count"=>1}])
      end
      
      it "sorts the date_histogram facet by count descending, by default" do
        expect(subject.format_facets(date_facets, nil)['sourceResource.date.begin.year']['entries'])
          .to eq([{"time"=>"2000", "count"=>2}, {"time"=>"1975", "count"=>1}])
      end
      
      it "identifies date facets with century interval as _type: 'date_histogram'" do
        expect(subject.format_facets(date_facets, nil)['sourceResource.date.begin.century']['_type'])
          .to eq 'date_histogram'
      end

      it "formats and sorts date facets with century interval like native date_histogram facets" do
        expect(subject.format_facets(date_facets, nil)['sourceResource.date.begin.century']['entries'])
          .to eq([{"time"=>"2000", "count"=>1}, {"time"=>"1900", "count"=>9}])
      end

      it "formats and sorts date facets with decade interval like native date_histogram facets" do
        expect(subject.format_facets(date_facets, nil)['sourceResource.date.begin.decade']['entries'])
          .to eq([{"time"=>"1980", "count"=>6}, {"time"=>"1970", "count"=>3}])
      end
      
      it "formats language facets" do
        expected = {
          "sourceResource.language.iso639_3" => {
            "_type" => "terms",
            "terms" => [
              {"term"=>"eng", "count"=>292},
              {"term"=>"jpn", "count"=>19},
              {"term"=>"lat", "count"=>6}
            ]
          }
        }
        actual = subject.format_facets(language_facets, nil)
        expect(actual).to eq expected
      end

      it "formats geo coordinate facets" do
        expected = {
          "sourceResource.spatial.coordinates" => {
            "_type" => "geo_distance",
            "ranges" => [
              {
                "from" => 0,
                "to" => 100,
                "count" => 0
              },
              {
                "from" => 100,
                "to" => 200,
                "count" => 5
              },
              {
                "from" => 200,
                "to" => 300,
                "count" => 4
              }
            ]
          }
        }
        actual = subject.format_facets(geo_facets, nil)
        expect(actual).to eq expected
      end

      it "enforces facet_size limit" do
        # returned facets should all have 1 value hash in them
        formatted = subject.format_facets(date_facets, 1)
        
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
        expect(subject.format_results(docs, {})).to match_array(
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
        expect(subject.format_results(docs, {})).to match_array(
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
        expect(subject.format_results(docs, {})).to match_array(
          [{}]
        )
      end

    end

    describe "#flatten_fields!" do
      it "flattens fields correctly" do
        doc_source = {
          "id" => "77d5d0016b2e4b45e0efa9d3dea16912",
          "sourceResource" => {"title" => ["House on West Adams"]},
          "object" => "https://thumbnails.calisphere.org/clip/150x150/b5cf866178a138dbcfaacb485c6b05d5"
        }
        params = {"fields" => "id,sourceResource.title,object"}
        expected = {
          "sourceResource.title" => ["House on West Adams"],
          "id" => "77d5d0016b2e4b45e0efa9d3dea16912",
          "object" => "https://thumbnails.calisphere.org/clip/150x150/b5cf866178a138dbcfaacb485c6b05d5"
        }
        subject.flatten_fields!(doc_source, params)
        expect(doc_source).to eq expected
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
      let(:httparty_response) { double('httparty_response').as_null_object }
      let(:response_value) { double('response_value').as_null_object }

      before(:each) do
        HTTParty.stub(:post).with(anything(), anything()) { httparty_response }
        httparty_response.stub(:response) { response_value }
        response_value.stub(:code) { "200" }
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

      it "returns search.results() with dictionary wrapper" do
        params = {'q' => 'banana'}
        results = double("results")
        dictionary_results = double("dictionary_wrapped")
        httparty_response.stub(:results) { results }
        subject.stub(:wrap_results).with(httparty_response, params) { dictionary_results }
        expect(subject.search(params)).to eq dictionary_results
      end

      it "limits the requested fields if fields param is present" do
        Searchable::Query.stub(:build_all) {{}}
        Searchable::Facet.stub(:build_all) {{}}
        subject.stub(:search_offset) {0}
        subject.stub(:search_page_size) {0}
        params = {'fields' => 'x,y'}
        subject.should_receive(:search_fields).with(params).and_return({})
        subject.search(params)
      end

      it "raises InternalServerSearchError on HTTP error response from ES" do
        response_value.stub(:code) { "400" }
        expect {subject.search()}.to raise_error(V1::InternalServerSearchError)
      end

    end

    describe "#search_fields" do
      it "returns a hash w '_source' property in proper format for 'fields' param" do
        params = {'fields' => 'x,y'}
        expect(subject.search_fields(params)).to eq({'_source' => ['x', 'y']})
      end

      it "returns empty hash for params with no 'fields' property" do
        expect(subject.search_fields({})).to eq({})
      end
    end

    describe "#actual_field" do
      it "returns actual field name if it has no modifier" do
        expect(subject.actual_field("sourceResource.title"))
          .to eq "sourceResource.title"
      end
      it "returns actual field name for a date field with modifier" do
        expect(subject.actual_field("sourceResource.date.begin.decade"))
          .to eq "sourceResource.date.begin"
      end
      it "returns actual field name for a coordinates field with modifier" do
        expect(subject.actual_field("sourceResource.spatial.coordinates:42:-77"))
          .to eq "sourceResource.spatial.coordinates"
      end
    end

  end

end
