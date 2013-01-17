require 'v1/searchable/facet'

module V1

  module Searchable

    describe Facet do      

      context "Constants" do
        describe "DATE_INTERVALS" do
          it "has the correct value" do
            expect(subject::DATE_INTERVALS).to match_array( %w( year month week day ) )
          end
        end
      end
      
      describe "#build_all" do
        it "returns true if it created any facets"
        it "returns false if it created zero facets" do
          expect(subject.build_all(stub, {}, false)).to be_false
        end
        it "calls the search.facet block with the correct params"
      end

      # describe "#validate_params" do
      #   it "does not raise error when all params are facetable" do
      #     V1::Schema::Field.any_instance.stub(:facetable?) { true }
      #     expect {
      #       subject.validate_params(['title'])
      #     }.not_to raise_error BadRequestSearchError
      #   end
      #   it "does not raise error when params is empty" do
      #     expect {
      #       subject.validate_params([])
      #     }.not_to raise_error BadRequestSearchError
      #   end
      #   context "date facets" do
      #     it "does not raise error for a valid temporal date facet" do
      #       expect {
      #         subject.validate_params(['temporal.start'])
      #       }.not_to raise_error BadRequestSearchError
      #     end
      #     it "does not raise error for a valid temporal date facet and interval" do
      #       expect {
      #         subject.validate_params(['temporal.start.month'])
      #       }.not_to raise_error BadRequestSearchError
      #     end
      #     it "does not raise error for a valid date facet and interval" do
      #       expect {
      #         subject.validate_params(['created.year'])
      #       }.not_to raise_error BadRequestSearchError
      #     end
      #     it "raises an error for a valid date facet and an invalid interval/trailing-junk" do
      #       expect {
      #         subject.validate_params(['created.invalid_interval_name'])
      #       }.to raise_error BadRequestSearchError
      #     end
      #   end
      #   context "geo facets" do
      #     it "does not raise error for a valid geo facet with modifiers" do
      #       expect {
      #         subject.validate_params(['spatial.coordinates:41:-71:20mi'])
      #       }.not_to raise_error BadRequestSearchError
      #     end
      #     it "raises an error for geo_point-formatted params on non-geo_point (or invalid) fields" do
      #       expect {
      #         subject.build_all(stub, {'facets' => 'foo.bar:42:-71:50mi'})
      #       }.to raise_error /Facet 'foo.bar' looks like geo_distance facet, but it is invalid/i
      #     end

      #   end
      # end

      describe "#parse_facet_name" do
        it "returns the result of V1::Schema.flapping" do
          field = stub
          V1::Schema.should_receive(:flapping).with('item', 'format') { field }
          expect(subject.parse_facet_name('format')).to eq field
        end
        it "parses geo_distance facet name with no modifier" do
          V1::Schema.should_receive(:flapping).with('item', 'spatial.coordinates')
          subject.parse_facet_name('spatial.coordinates')
        end
        it "parses geo_distance facet name with modifier" do
          V1::Schema.should_receive(:flapping).with('item', 'spatial.coordinates', '42.3:-71:20mi')
          subject.parse_facet_name('spatial.coordinates:42.3:-71:20mi')
        end
        it "parses date facet name with no modifier" do
          V1::Schema.should_receive(:flapping).with('item', 'created')
          subject.parse_facet_name('created')
        end
        it "parses date facet name with modifier" do
          V1::Schema.should_receive(:flapping).with('item', 'created', 'year')
          subject.parse_facet_name('created.year')
        end
        it "parses date facet subfield name with modifier" do
          V1::Schema.should_receive(:flapping).with('item', 'temporal.start', 'year')
          subject.parse_facet_name('temporal.start.year')
        end
      end

      describe "#facet_options" do
        it "raises an error for geo_point facet missing a lat/lon value" do
          field = stub('field', :name => 'spatial.coordinates', :geo_point? => true, :facet_modifier => nil)
          expect {
            subject.facet_options(field)
          }.to raise_error BadRequestSearchError, /Facet 'spatial.coordinates' missing lat\/lon modifiers/i
        end
        it "returns correct options for geo_point fields"  do
          field = stub('field', :name => 'spatial.coordinates', :geo_point? => true, :facet_modifier => '42:-71:50mi')
          geo_facet_stub = stub
          subject.stub(:geo_facet_ranges) { geo_facet_stub }
          expect(
                 subject.facet_options(field)
                 ).to eq(
                         {
                           'spatial.coordinates' => '42,-71',
                           'ranges' => geo_facet_stub,
                           'unit' => 'mi'
                         }
                         )
        end
        it "returns correct options for date fields with an interval"  do
          field = stub('field', :name => 'created', :geo_point? => false, :date? => true, :facet_modifier => 'year')
          dfo_stub = stub('date_facet_options', :any? => true)
          subject.stub(:date_facet_options) { dfo_stub }
          expect(subject.facet_options(field)).to eq(dfo_stub)
        end
        it "returns empty hash for anything else" do
          field = stub('format', :geo_point? => false, :date? => false)
          expect(subject.facet_options(field)).to eq({})
        end
      end

      describe "#geo_facet_ranges" do
        it "creates the correct buckets with the default bucket" do
          expect(subject.geo_facet_ranges(nil))
            .to match_array(
                            [
                             {"to"=>100},
                             {"from"=>100, "to"=>200},
                             {"from"=>200, "to"=>300},
                             {"from"=>300, "to"=>400},
                             {"from"=>400, "to"=>500},
                             {"from"=>500, "to"=>600},
                             {"from"=>600, "to"=>700},
                             {"from"=>700, "to"=>800},
                             {"from"=>800, "to"=>900},
                             {"from"=>900}
                            ]
                            )
        end
        it "creates the correct buckets with a user-supplied bucket" do
          expect(subject.geo_facet_ranges('50mi'))
            .to match_array(
                            [
                             {"to"=>50},
                             {"from"=>50, "to"=>100},
                             {"from"=>100, "to"=>150},
                             {"from"=>150, "to"=>200},
                             {"from"=>200, "to"=>250},
                             {"from"=>250, "to"=>300},
                             {"from"=>300, "to"=>350},
                             {"from"=>350, "to"=>400},
                             {"from"=>400, "to"=>450},
                             {"from"=>450}
                            ]
                            )
        end
      end

      describe "#date_facet_options" do
        it "handles date fields with a valid interval" do
          expect(subject.date_facet_options('created.day')
                 ).to eq( { :field => 'created', :interval => 'day' } )
        end
        it "handles date fields with an invalid interval" do
          expect(subject.date_facet_options('created.invalid_interval_name')
                 ).to eq( {} )
        end
        it "handles date fields with no interval" do
          expect(subject.date_facet_options('created')
                 ).to eq( {} )
        end
        it "handles temporal date fields with no interval" do
          expect(subject.date_facet_options('temporal.start')
                 ).to eq( {} )
        end
        it "handles temporal date fields with a valid interval" do
          expect(subject.date_facet_options('temporal.start.month')
                 ).to eq( { :field => 'temporal.start', :interval => 'month' } )
        end
      end

      describe "#date_interval" do
        before(:each) do
          stub_const("V1::Searchable::Facet::DATE_INTERVALS", %w(year month))
        end

        it "returns correct array for a date with a valid interval" do
          expect(subject.date_interval('foo.year')).to eq(['foo', 'year'])
        end
        it "returns empty array for anything else" do
          expect(subject.date_interval('foo.banana')).to eq([])
          expect(subject.date_interval('foo')).to eq([])
        end
      end

      describe "#facet_type" do
        it "returns 'geo_distance' for geo_point type fields" do
          field = stub('spatial.coordinates', :type => 'geo_point')
          expect(subject.facet_type(field)).to eq 'geo_distance'
        end
        
        it "returns 'date' for date type fields" do
          field = stub('created', :type => 'date')
          expect(subject.facet_type(field)).to eq 'date'
        end
        
        it "returns 'terms' for string type fields" do
          field = stub('format', :type => 'string')
          expect(subject.facet_type(field)).to eq 'terms'
        end
      end

      describe "#facet_field" do
        it "handles a top level field" do
          field = stub(:name => 'title', :multi_fields => [])
          expect(subject.facet_field(field)).to eq field.name
        end
        it "handles a multi_field field with a .raw subfield" do
          multi1 = stub(:name => 'isPartOf.name.name', :facetable? => false)
          multi2 = stub(:name => 'isPartOf.name.raw', :facetable? => true)
          field = stub(:name => 'isPartOf.name', :multi_fields => [multi1, multi2])
          expect(subject.facet_field(field)).to eq 'isPartOf.name.raw'
        end
        it "handles a date field with an interval" do
          field = stub(:name => 'created', :facet_modifier => 'year', :multi_fields => [])
          expect(subject.facet_field(field)).to eq 'created'
        end
      end

      describe "#expand_facet_fields" do
        let(:resource) { 'item' }

        it "returns all facetable subfields for a non-facetable field" do
          subfield = stub('sub', :facetable? => true, :name => 'somefield.sub2a')
          field = stub('field', :facetable? => false, :name => 'somefield', :subfields => [subfield])
          V1::Schema.stub(:flapping).with(resource, 'somefield') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( somefield ) )
                 ).to match_array %w( somefield.sub2a )
        end
        it "returns a facetable field with no subfields" do
          field = stub('field', :facetable? => true, :name => 'id', :subfields => [])
          V1::Schema.stub(:flapping).with(resource, 'id') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( id ) )
                 ).to match_array %w( id )
        end
        it "returns a non-facetable field with no facetable subfields" do
          field = stub('field', :facetable? => false, :name => 'description', :subfields => [])
          V1::Schema.stub(:flapping).with(resource, 'description') { field }
          expect(
                 subject.expand_facet_fields(resource, %w( description ) )
                 ).to match_array %w( description )
        end
        it "returns the correct values when called with a mix of fields" do
          subfield = stub('sub', :facetable? => true, :name => 'somefield.sub2a')
          somefield = stub('field', :facetable? => false, :name => 'somefield', :subfields => [subfield])
          V1::Schema.stub(:flapping).with(resource, 'somefield') { somefield }

          id_field = stub('field', :facetable? => true, :name => 'id', :subfields => [])
          V1::Schema.stub(:flapping).with(resource, 'id') { id_field }

          expect(
                 subject.expand_facet_fields(resource, %w( somefield id  ) )
                 ).to match_array %w( somefield.sub2a id )
        end

      end

    end

  end

end
