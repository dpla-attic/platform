require 'v1/searchable/query'

module V1

  module Searchable

    describe Query do
      let(:resource) { 'test_resource' }

      describe "#build_all" do
        it "executes an empty search if no explicit queries are created" do
          expect(subject.build_all(resource, {}).key?('match_all')).to eq(true)
        end
      end

      describe "#field_boost" do
        
        it "handles a boosted field with no subfields" do
          field = double(:name => 'field1', :subfields? => false)
          subject.stub(:field_boost_for) { 42 }
          expect(subject.field_boost('testitem', field)).to eq "field1^42"
        end
        
        it "handles a boosted field with subfields" do
          field = double(:name => 'field1', :subfields? => true)
          subject.stub(:field_boost_for) { 42 }
          expect(subject.field_boost('testitem', field)).to eq "field1.*^42"
        end
        
      end

      describe "#default_attributes" do
        it "contains the expects attrs" do
        expect(subject.default_attributes)
          .to eq ({
                  'default_operator' => 'AND',
                  'lenient' => true
                  })
        end
      end

      describe "#string_queries" do
        it "returns correct query string for a free text search" do
          params = {'q' => 'something'}
          attrs = subject.default_attributes.merge( {'fields'=>['_all']} )
          # e.g.:
          # [
          #   [
          #     "something",
          #     {
          #       "default_operator"=>"AND",
          #       "lenient"=>true,
          #       "fields"=>["_all"]
          #     }
          #   ]
          # ]
          expect(subject.string_queries(resource, params))
            .to match_array(
                            [['something', attrs]]
                            )
        end
        
        it "returns correct query string for field search" do
          name = 'sourceResource.title'
          field = double(:name => name, :geo_point? => false, :date? => false, 
            :multi_field_date? => false, :subfields? => false, :subfields => [],
            :compound_fields => nil)
          subject.stub(:field_for).with(resource, name) { field }
          params = {name => 'some title'}
          attrs = subject.default_attributes.merge( {'fields'=>[name]} )
          expect(subject.string_queries(resource, params))
            .to match_array(
                            [['some title', attrs]]
                            )
        end

        it "handles 'sourceResource.spatial.state' as a normal field search" do
          name = 'sourceResource.spatial.state'
          field = double(:name => name, :geo_point? => false, :date? => false, 
            :multi_field_date? => false, :subfields? => false, :subfields => [],
            :compound_fields => nil)
          Schema.stub(:field).with(resource, name) { field }
          params = {name => 'MA'}
          attrs = subject.default_attributes.merge( {'fields'=>[name]} )
          expect(subject.string_queries(resource, params))
            .to match_array(
                            [['MA', attrs]]
                            )
        end

        it "ignores geo_point field" do
          name = 'sourceResource.spatial.coordinates'
          field = double(:name => name, :geo_point? => true, :date? => false, :multi_field_date? => false)
          Schema.stub(:field).with(resource, name) { field }
          params = {name => '42,-71'}
          expect(subject.string_queries(resource, params)).to match_array []
        end

        it "searches all subfields of 'sourceResource.date'" do
          name = 'sourceResource.date'
          field = double(:name => name, :geo_point? => false, :date? => false, 
            :multi_field_date? => false, :subfields? => true, :subfields => [double.as_null_object],
            :compound_fields => nil)
          Schema.stub(:field).with(resource, name) { field }
          params = {name => '1999-08-07'}
          attrs = subject.default_attributes.merge( {'fields' => ['sourceResource.date.*']} )
          expect(subject.string_queries(resource, params))
            .to match_array(
                            [['1999-08-07', attrs]]
                            )
        end

        it "handles an empty search correctly" do
          params = {}
          expect(subject.string_queries(resource, params)).to match_array []
        end

        it "treats fields correctly with `exact_field_match' but does not " +
           "quote the `q' parameter" do
          params = {
            'dataProvider' => 'Provider A',
            'q' => 'wonderful things',
            'exact_field_match' => 'true'
          }
          result = subject.string_queries('item', params)
          expect(result[0][0]).to eq '"Provider A"'      # quoted
          expect(result[1][0]).to eq 'wonderful things'  # not quoted
        end

      end

      describe "#date_range_queries" do

        it "raises BadRequestSearchError for invalid date values" do
          params = {'temporal.after' => 'boop'}
          expect {
            subject.date_range_queries(params)
          }.to raise_error BadRequestSearchError, /Invalid date in temporal.after field/
        end
        
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

      describe "#protect_metacharacters" do
        
        it "escapes multiple meta-characters" do
          string = 'harvard (lol)'
          expect(subject.protect_metacharacters(string)).to eq 'harvard \\(lol\\)'
        end
        
        it "does not escape '*' meta-character" do
          string = 'harv*'
          expect(subject.protect_metacharacters(string)).to eq string
        end

        it "preserves double-quote wrapping" do
          string = '"harv"'
          expect(subject.protect_metacharacters(string)).to eq string
        end

        it "escapes internal double quotes" do
          string = 'ha"rv'
          expect(subject.protect_metacharacters(string)).to eq 'ha\\"rv'
        end

        it "escapes internal double quotes and preserves double-quote wrapping" do
          string = '"ha"rv"'
          expect(subject.protect_metacharacters(string)).to eq '"ha\\"rv"'
        end

        it "escapes internal double quotes without double-escaping them" do
          string = '"ha\\"rv"'
          expect(subject.protect_metacharacters(string)).to eq '"ha\\"rv"'
        end

        it "escapes meta-characters at the beginning of a string" do
          string = '?harv'
          expect(subject.protect_metacharacters(string)).to eq '\\?harv'
        end

        it "escapes meta-characters just absolutely everywhere" do
          string = '}?harv[a:z](/'
          expect(subject.protect_metacharacters(string)).to eq '\\}\\?harv\\[a\\:z\\]\\(\\/'
        end

        it "returns a quoted string if exact_field_match is specified" do
          string = 'University of Pennsylvania'
          expect(subject.protect_metacharacters(string, true))
            .to eq '"University of Pennsylvania"'
        end

      end

    end

  end

end

