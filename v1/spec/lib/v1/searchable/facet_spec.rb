require 'v1/searchable/facet'

module V1

  module Searchable

    describe Facet do
      let(:resource) { 'test_resource' }

      describe "CONSTANTS" do
        it "DATE_INTERVALS has the correct value" do
          expect(subject::DATE_INTERVALS).to match_array( %w( century decade year month day ) )
        end
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
      
      describe "#build_all" do
        it "returns true if it created any facets"
        it "returns false if it did not create any facets" do
          expect(subject.build_all(resource, stub, {}, false)).to be_false
        end
        it "calls the search.facet block with the correct params"
      end

      describe "#parse_facet_name" do
        it "returns the result of V1::Schema.field" do
          field = stub
          V1::Schema.should_receive(:field).with(resource, 'format') { field }
          expect(subject.parse_facet_name(resource, 'format')).to eq field
        end
        it "parses geo_distance facet name with no modifier" do
          V1::Schema.should_receive(:field).with(resource, 'spatial.coordinates')
          subject.parse_facet_name(resource, 'spatial.coordinates')
        end
        it "parses geo_distance facet name with modifier" do
          V1::Schema.should_receive(:field).with(resource, 'spatial.coordinates', '42.3:-71:20mi')
          subject.parse_facet_name(resource, 'spatial.coordinates:42.3:-71:20mi')
        end
        it "parses date facet name with no modifier" do
          V1::Schema.should_receive(:field).with(resource, 'date')
          subject.parse_facet_name(resource, 'date')
        end
        it "parses date facet name with modifier" do
          V1::Schema.should_receive(:field).with(resource, 'date', 'year')
          subject.parse_facet_name(resource, 'date.year')
        end
        it "parses date facet subfield name with modifier" do
          V1::Schema.should_receive(:field).with(resource, 'temporal.begin', 'year')
          subject.parse_facet_name(resource, 'temporal.begin.year')
        end
      end

      describe "#facet_options" do
        it "raises an error for geo_point facet missing a lat/lon value" do
          field = stub(:name => 'spatial.coordinates', :geo_point? => true, :facet_modifier => nil)
          expect {
            subject.facet_options('geo_distance', field, {})
          }.to raise_error BadRequestSearchError, /Facet 'spatial.coordinates' missing lat\/lon modifiers/i
        end
        it "returns correct options for geo_point fields with no range"  do
          field = stub(:name => 'spatial.coordinates', :facet_modifier => '42:-71')
          geo_facet_stub = stub
          subject.should_receive(:facet_ranges)
            .with(
                  subject::DEFAULT_GEO_DISTANCE_MILES,
                  subject::DEFAULT_GEO_DISTANCE_MILES,
                  subject::DEFAULT_GEO_BUCKETS,
                  true
                  ) { geo_facet_stub }
          expect(subject.facet_options('geo_distance', field, {}))
            .to eq(
                   {
                     'spatial.coordinates' => '42,-71',
                     'ranges' => geo_facet_stub,
                     'unit' => 'mi'
                   }
                   )
        end
        it "returns correct options for geo_point fields with explicit range"  do
          field = stub(:name => 'spatial.coordinates', :facet_modifier => '42:-71:50mi')
          geo_facet_stub = stub
          subject.stub(:facet_ranges) { geo_facet_stub }
          expect(subject.facet_options('geo_distance', field, {}))
            .to eq(
                   {
                     'spatial.coordinates' => '42,-71',
                     'ranges' => geo_facet_stub,
                     'unit' => 'mi'
                   }
                   )
        end
        it "returns correct options for date_histogram facet with a native interval"  do
          field = stub(:name => 'date', :facet_modifier => 'year')
          expect(subject.facet_options('date', field, {}))
            .to eq(
                   {:interval => 'year', :order => 'count'}
                   )
        end
        it "raises an error for an unrecognized interval on a date_histogram facet" do
          field = stub(:name => 'date', :facet_modifier => 'invalid_interval')
          expect {
            subject.facet_options('date', field, {})
          }.to raise_error BadRequestSearchError, /date facet 'date.invalid_interval' has invalid interval/i
        end
        it "returns correct default interval for date_histogram facet with no interval"  do
          field = stub(:name => 'date', :facet_modifier => nil)
          expect(subject.facet_options('date', field, {}))
            .to eq(
                   { :interval => 'day', :order => 'count' }
                   )
        end
        it "returns correct hash for decade date range facet"  do
          field = stub(:name => 'date', :facet_modifier => 'decade')
          ranges_stub = stub
          subject.stub(:facet_ranges).with(100, 10, 200, false) { ranges_stub}
          expect(subject.facet_options('range', field, {}))
            .to eq(
                   options = {
                     'field' => 'date',
                     'ranges' => ranges_stub
                   }
                   )
        end
        it "returns correct hash for century date range facet"  do
          field = stub(:name => 'date', :facet_modifier => 'century')
          ranges_stub = stub
          subject.stub(:facet_ranges).with(100, 100, 20, false) { ranges_stub}
          expect(subject.facet_options('range', field, {}))
            .to eq(
                   options = {
                     'field' => 'date',
                     'ranges' => ranges_stub
                   }
                   )
        end
        it "returns size and order hash for terms filter" do
          field = stub(:string? => true)
          expect(subject.facet_options('terms', field, {}))
            .to eq(
                   { :size => 50, :order => 'count' }
                   )
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

      describe "#facet_type" do
        it "returns 'geo_distance' for geo_point type fields" do
          field = stub('spatial.coordinates', :geo_point? => true)
          expect(subject.facet_type(field)).to eq 'geo_distance'
        end
        
        it "returns 'date' for date type field with no interval" do
          field = stub('date', :geo_point? => false, :date? => true, :facet_modifier => nil)
          expect(subject.facet_type(field)).to eq 'date'
        end
        
        it "returns 'date' for date type field with a date_histogram interval" do
          field = stub('date', :geo_point? => false, :date? => true, :facet_modifier => 'year')
          expect(subject.facet_type(field)).to eq 'date'
        end
        
        it "returns 'range' for date type field with a custom range interval" do
          field = stub('date', :geo_point? => false, :date? => true, :facet_modifier => 'century')
          expect(subject.facet_type(field)).to eq 'range'
          field = stub('date', :geo_point? => false, :date? => true, :facet_modifier => 'decade')
          expect(subject.facet_type(field)).to eq 'range'
        end
        
        it "returns 'terms' for string type fields" do
          field = stub('date', :geo_point? => false, :date? => false, :facet_modifier => nil)
          expect(subject.facet_type(field)).to eq 'terms'
        end
      end

      describe "#facet_field_name" do
        it "handles a top level field" do
          field = stub(:name => 'title', :multi_fields => [])
          expect(subject.facet_field_name(field)).to eq field.name
        end
        it "handles a multi_field field with a .raw subfield" do
          multi1 = stub(:name => 'isPartOf.name.name', :facetable? => false)
          multi2 = stub(:name => 'isPartOf.name.raw', :facetable? => true)
          field = stub(:name => 'isPartOf.name', :multi_fields => [multi1, multi2])
          expect(subject.facet_field_name(field)).to eq 'isPartOf.name.raw'
        end
        it "handles a date field with an interval" do
          field = stub(:name => 'date', :facet_modifier => 'year', :multi_fields => [])
          expect(subject.facet_field_name(field)).to eq 'date'
        end
      end

      describe "#expand_facet_fields" do

        it "returns all facetable subfields for a non-facetable field" do
          subfield = stub('sub', :facetable? => true, :name => 'somefield.sub2a', :geo_point? => false)
          field = stub('field', :facetable? => false, :name => 'somefield', :subfields => [subfield], :geo_point? => false)
          V1::Schema.stub(:field).with(resource, 'somefield') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( somefield ) )
                 ).to match_array %w( somefield.sub2a )
        end
        it "returns a facetable field with no subfields" do
          field = stub('field', :facetable? => true, :name => 'id', :subfields => [])
          V1::Schema.stub(:field).with(resource, 'id') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( id ) )
                 ).to match_array %w( id )
        end

        it "returns a non-facetable field with no facetable subfields" do
          field = stub('field', :facetable? => false, :name => 'description', :subfields => [])
          V1::Schema.stub(:field).with(resource, 'description') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( description ) )
                 ).to match_array %w( description )
        end


        it "returns all facetable subfields for a non-facetable field" do
          sub1 = stub('sub1', :facetable? => true, :name => 'somefield.sub2a', :geo_point? => false)
          sub2 = stub('sub2', :facetable? => true, :name => 'somefield.sub2a_geo', :geo_point? => true)
          field = stub('field', :facetable? => false, :name => 'somefield', :subfields => [sub1, sub2], :geo_point? => false)
          V1::Schema.stub(:field).with(resource, 'somefield') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( somefield ) )
                 ).to match_array %w( somefield.sub2a )
        end

        it "returns the correct values when called with a mix of fields" do
          subfield = stub('sub', :facetable? => true, :name => 'somefield.sub2a', :geo_point? => false)
          somefield = stub('field', :facetable? => false, :name => 'somefield', :subfields => [subfield], :geo_point? => false)
          V1::Schema.stub(:field).with(resource, 'somefield') { somefield }

          id_field = stub('field', :facetable? => true, :name => 'id', :subfields => [])
          V1::Schema.stub(:field).with(resource, 'id') { id_field }

          expect(
                 subject.expand_facet_fields(resource, %w( somefield id  ) )
                 ).to match_array %w( somefield.sub2a id )
        end

      end

      describe "#facet_display_name" do
        it "returns correct value for non-modified date facets" do
          field = stub(:name => 'somename', :date? => false )
          expect(subject.facet_display_name(field)).to eq 'somename'
        end
        it "returns correct value for date facets with a facet modifier" do
          field = stub(:name => 'somename', :date? => true, :facet_modifier => 'modified' )
          expect(subject.facet_display_name(field)).to eq 'somename.modified'
        end
      end

      describe "#facet_size" do
        before(:each) do
          stub_const("V1::Searchable::Facet::DEFAULT_FACET_SIZE", 19)
          stub_const("V1::Searchable::Facet::MAXIMUM_FACET_SIZE", 42)
        end
        it "returns MAXIMUM_FACET_SIZE when 'max' is passed" do
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

    end

  end

end
