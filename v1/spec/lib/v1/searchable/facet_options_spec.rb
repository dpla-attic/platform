require 'v1/searchable/facet'

module V1

  module Searchable

    describe FacetOptions do
      let(:resource) { 'test_resource' }

      describe "CONSTANTS" do
        it "DEFAULT_FACET_SIZE has correct value" do
          expect(subject::DEFAULT_FACET_SIZE).to eq 50
        end
        it "MAXIMUM_FACET_SIZE has correct value" do
          expect(subject::MAXIMUM_FACET_SIZE).to eq 2000
        end
        it "DEFAULT_GEO_DISTANCE_MILES has correct value" do
          expect(subject::DEFAULT_GEO_DISTANCE_MILES).to eq 100
        end
        it "DEFAULT_GEO_BUCKETS has correct value" do
          expect(subject::DEFAULT_GEO_BUCKETS).to eq 20
        end

      end

      describe "#build_options" do
        it "raises an error for geo_point facet missing a lat/lon value" do
          field = double(:name => 'spatial.coordinates', :geo_point? => true, :facet_modifier => nil)
          expect {
            subject.build_options('geo_distance', field, {})
          }.to raise_error BadRequestSearchError, /Facet 'spatial.coordinates' missing lat\/lon modifiers/i
        end
        it "returns correct options for geo_point fields with no range"  do
          field = double(:name => 'spatial.coordinates', :facet_modifier => '42:-71')
          geo_facet_stub = double
          subject.should_receive(:facet_ranges)
            .with(
                  subject.default_geo_distance_miles,
                  subject.default_geo_distance_miles,
                  subject.default_geo_buckets,
                  true
                  ) { geo_facet_stub }
          expect(subject.build_options('geo_distance', field, {}))
            .to eq(
                   {
                     'spatial.coordinates' => '42,-71',
                     'ranges' => geo_facet_stub,
                     'unit' => 'mi'
                   }
                   )
        end
        it "returns correct options for geo_point fields with explicit range"  do
          field = double(:name => 'spatial.coordinates', :facet_modifier => '42:-71:50mi')
          geo_facet_stub = double
          subject.stub(:facet_ranges) { geo_facet_stub }
          expect(subject.build_options('geo_distance', field, {}))
            .to eq(
                   {
                     'spatial.coordinates' => '42,-71',
                     'ranges' => geo_facet_stub,
                     'unit' => 'mi'
                   }
                   )
        end
        it "returns correct options for date_histogram facet with a native interval"  do
          field = double(:name => 'date', :facet_modifier => 'year')
          expect(subject.build_options('date', field, {}))
            .to eq({
                     :interval => 'year',
                     :order => 'count'
                   })
        end
        it "raises an error for an unrecognized interval on a date_histogram facet" do
          field = double(:name => 'date', :facet_modifier => 'invalid_interval')
          expect {
            subject.build_options('date', field, {})
          }.to raise_error BadRequestSearchError, /date facet 'date.invalid_interval' has invalid interval/i
        end
        it "returns correct default interval for date_histogram facet with no interval"  do
          field = double(:name => 'date', :facet_modifier => nil)
          expect(subject.build_options('date', field, {}))
            .to eq({
                     :interval => 'day',
                     :order => 'count'
                   })
        end
        it "returns correct hash for decade date range facet"  do
          field = double(:name => 'date', :facet_modifier => 'decade')
          ranges_stub = double
          subject.stub(:facet_ranges).with(100, 10, 200, false) { ranges_stub}
          expect(subject.build_options('range', field, {}))
            .to eq({
                     'field' => 'date',
                     'ranges' => ranges_stub
                   })
        end
        it "returns correct hash for century date range facet"  do
          field = double(:name => 'date', :facet_modifier => 'century')
          ranges_stub = double
          subject.stub(:facet_ranges).with(100, 100, 20, false) { ranges_stub}
          expect(subject.build_options('range', field, {}))
            .to eq({
                     'field' => 'date',
                     'ranges' => ranges_stub
                   })
        end
        it "returns size and order hash for terms filter" do
          subject.stub(:filter_facet) {{}}
          field = double(:name => 'subject.name', :string? => true)
          expect(subject.build_options('terms', field, {}))
            .to eq({
                     :size => 50,
                     :order => 'count'
                   })
        end
      end

      
      describe "#facet_ranges" do
        it "creates correct ranges, starting from zero, with no endcaps" do
          expect(subject.facet_ranges(0, 100, 4, false))
            .to match_array(
                            [
                             {"from"=>"0", "to"=>"100"},
                             {"from"=>"100", "to"=>"200"},
                             {"from"=>"200", "to"=>"300"},
                             {"from"=>"300", "to"=>"400"}
                            ]
                            )
        end
        it "creates correct ranges, starting from non-zero, with no endcaps" do
          expect(subject.facet_ranges(50, 100, 4, false))
            .to match_array(
                            [
                             {"from"=>"50", "to"=>"150"},
                             {"from"=>"150", "to"=>"250"},
                             {"from"=>"250", "to"=>"350"},
                             {"from"=>"350", "to"=>"450"}
                            ]
                            )
        end
        it "creates the correct ranges, starting from zero, with endcaps" do
          expect(subject.facet_ranges(0, 100, 4, true))
            .to match_array(
                            [
                             {"to"=>"0"},
                             {"from"=>"0", "to"=>"100"},
                             {"from"=>"100", "to"=>"200"},
                             {"from"=>"200", "to"=>"300"},
                             {"from"=>"300", "to"=>"400"},
                             {"from"=>"400"}
                            ]
                            )
        end
        it "creates the correct ranges, starting from non-zero, with endcaps" do
          expect(subject.facet_ranges(50, 100, 4, true))
            .to match_array(
                            [
                             {"to"=>"50"},
                             {"from"=>"50", "to"=>"150"},
                             {"from"=>"150", "to"=>"250"},
                             {"from"=>"250", "to"=>"350"},
                             {"from"=>"350", "to"=>"450"},
                             {"from"=>"450"}
                            ]
                            )
        end
        it "goes ok" do
          subject.facet_ranges(10, 10, 20, true)
        end
      end

      describe "#facet_size" do
        before(:each) do
          subject.stub(:default_facet_size) { 19 }
          subject.stub(:maximum_facet_size) { 42 }
        end
        it "returns maximum_facet_size when 'max' is passed" do
          params = {'facet_size' => 'max'}
          expect(subject.facet_size(params)).to eq 42
        end
        it "returns default value when no facet_size param is present" do
          params = {}
          expect(subject.facet_size(params)).to eq 19
        end
        it "limits maximum value" do
          params = {'facet_size' => 9999}
          expect(subject.facet_size(params)).to eq 42
        end
        it "parses and returns valid value" do
          params = {'facet_size' => 25}
          expect(subject.facet_size(params)).to eq 25
        end
        
      end


      describe "#filter_facet" do
        let(:facet_name) { 'city' }

        it "returns an empty hash if there is nothing to do" do
          params = {'q' => 'foo'}
          expect(subject.filter_facet(facet_name, params)).to eq({})
        end

        it "returns correct regex for a single word" do
          params = {"filter_facets" => facet_name, facet_name => 'house'}
          expect(subject.filter_facet(facet_name, params))
            .to eq({
                     'script_field' => "term.toLowerCase() ~= '.*house.*'"
                   })
        end

        it "returns correct regex for a double quoted string" do
          params = {"filter_facets" => facet_name, facet_name => '"haunted house"'}
          expect(subject.filter_facet(facet_name, params))
            .to eq({
                     'script_field' => "term.toLowerCase() ~= '.*haunted house.*'"
                   })
        end

        it "returns correct regex for a string containing a '*' wildcard" do
          params = {"filter_facets" => facet_name, facet_name => 'haunted *ouse'}
          expect(subject.filter_facet(facet_name, params))
            .to eq({
                     'script_field' => "term.toLowerCase() ~= '.*haunted .*ouse.*'"
                   })
        end

        it "returns correct regex for multiple bare words (default AND boolean search)" do
          params = {"filter_facets" => facet_name, facet_name => 'haunted house'}
          expect(subject.filter_facet(facet_name, params))
            .to eq({
                     'script_field' => "term.toLowerCase() ~= '.*(?=.*haunted)(?=.*house).*'"
                   })
        end

        it "returns correct regex for multiple words joined by OR boolean operator" do
          params = {"filter_facets" => facet_name, facet_name => 'haunted OR house'}
          expect(subject.filter_facet(facet_name, params))
            .to eq({
                     'script_field' => "term.toLowerCase() ~= '.*(haunted|house).*'"
                   })
        end

        # it "only applies filter_facet on facets for which it was requested" do
        #   params = {"filter_facets" => "date.begin,#{facet_name}", facet_name => 'house'}
        #   expect(subject.filter_facet(facet_name, params))
        #     .to eq({
        #              'script_field' => "term.toLowerCase() ~= '.*house.*'"
        #            })
        # end

        # OR!

        #  => 0
      end
    end
    
  end
  
end
