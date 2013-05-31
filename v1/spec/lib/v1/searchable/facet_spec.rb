require 'v1/searchable/facet'

module V1

  module Searchable

    describe Facet do
      let(:resource) { 'test_resource' }

      describe "CONSTANTS" do
        it "VALID_DATE_INTERVALS has the correct value" do
          expect(subject::VALID_DATE_INTERVALS).to match_array( %w( century decade year month day ) )
        end
        it "FILTER_FACET_FLAGS has the correct value" do
          expect(subject::FILTER_FACET_FLAGS).to match_array %w( CASE_INSENSITIVE DOTALL )
        end
      end
      
      describe "#build_all" do
        it "returns true if it created any facets"
        it "returns false if it did not create any facets" do
          expect(subject.build_all(resource, stub, {}, false)).to be_false
        end
        it "calls the search.facet block with the correct params"
        it "raises an error for a facet request on a invalid field" do
          invalid_name = 'invalid_field_name'
          field = stub(:facetable? => false)
          subject.stub(:expand_facet_fields) { [invalid_name] }
          subject.stub(:parse_facet_name) { nil }

          expect {
            subject.build_all(stub, stub, {'facets' => invalid_name})
          }.to raise_error BadRequestSearchError, /Invalid field.+ specified in facets param: #{invalid_name}/i

        end
        it "raises an error for a facet request on a valid, but not-facetable field" do
          field = stub(:facetable? => false)
          subject.stub(:expand_facet_fields) { ['title'] }
          subject.stub(:parse_facet_name) { field }

          expect {
            subject.build_all(stub, stub, {'facets' => 'title'})
          }.to raise_error BadRequestSearchError, /Non-facetable field.+ param: title/i
        end
      end


      describe "#parse_facet_name" do
        it "returns the result of Schema.field" do
          field = stub
          Schema.should_receive(:field).with(resource, 'format') { field }
          expect(subject.parse_facet_name(resource, 'format')).to eq field
        end
        it "parses geo_distance facet name with no modifier" do
          Schema.should_receive(:field).with(resource, 'spatial.coordinates')
          subject.parse_facet_name(resource, 'spatial.coordinates')
        end
        it "parses geo_distance facet name with modifier" do
          Schema.should_receive(:field).with(resource, 'spatial.coordinates', '42.3:-71:20mi')
          subject.parse_facet_name(resource, 'spatial.coordinates:42.3:-71:20mi')
        end
        it "parses date facet name with no modifier" do
          Schema.should_receive(:field).with(resource, 'date')
          subject.parse_facet_name(resource, 'date')
        end
        it "parses date facet name with modifier" do
          Schema.should_receive(:field).with(resource, 'date', 'year')
          subject.parse_facet_name(resource, 'date.year')
        end
        it "parses date facet subfield name with modifier" do
          Schema.should_receive(:field).with(resource, 'temporal.begin', 'year')
          subject.parse_facet_name(resource, 'temporal.begin.year')
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

      describe "#expand_facet_fields" do

        it "returns all facetable subfields for a non-facetable field" do
          subfield = stub(:facetable? => true, :name => 'somefield.sub2a', :geo_point? => false)
          field = stub(:facetable? => false, :name => 'somefield', :subfields => [subfield], :geo_point? => false)
          Schema.stub(:field).with(resource, 'somefield') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( somefield ) )
                 ).to match_array %w( somefield.sub2a )
        end

        it "returns a facetable field with no subfields" do
          field = stub(:facetable? => true, :name => 'id', :subfields => [])
          Schema.stub(:field).with(resource, 'id') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( id ) )
                 ).to match_array %w( id )
        end

        it "returns a non-facetable field with no facetable subfields" do
          field = stub(:facetable? => false, :name => 'description', :subfields => [])
          Schema.stub(:field).with(resource, 'description') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( description ) )
                 ).to match_array %w( description )
        end

        it "returns all facetable subfields for a non-facetable field" do
          sub1 = stub(:facetable? => true, :name => 'somefield.sub2a', :geo_point? => false)
          sub2 = stub(:facetable? => true, :name => 'somefield.sub2a_geo', :geo_point? => true)
          field = stub(:facetable? => false, :name => 'somefield', :subfields => [sub1, sub2], :geo_point? => false)
          Schema.stub(:field).with(resource, 'somefield') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( somefield ) )
                 ).to match_array %w( somefield.sub2a )
        end

        it "returns the correct values when called with a mix of fields" do
          subfield = stub(:facetable? => true, :name => 'somefield.sub2a', :geo_point? => false)
          somefield = stub(:facetable? => false, :name => 'somefield', :subfields => [subfield], :geo_point? => false)
          Schema.stub(:field).with(resource, 'somefield') { somefield }

          id_field = stub(:facetable? => true, :name => 'id', :subfields => [])
          Schema.stub(:field).with(resource, 'id') { id_field }

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


    end

  end

end
