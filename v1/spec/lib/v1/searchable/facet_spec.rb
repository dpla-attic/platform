require 'v1/searchable/facet'

module V1

  module Searchable

    describe Facet do      
      
      describe "#build_all" do
        it "returns true if it created any facets"
        it "returns false if it created zero facets" do
          expect(subject.build_all(stub, {}, false)).to be_false
        end
        it "preprocesses and validates the requested facets" do
          params = {'facets' => 'a, b'}
          requested = %w( a b )
          search = stub("search", :facet => nil)
          V1::Schema.should_receive(:expand_facet_fields).with('item', requested) { requested }
          subject.should_receive(:validate_params).with(requested)
          subject.build_all(search, params, false)
        end

        it "calls the search.facet block with the correct params"
      end

      describe "#validate_params" do
        it "does not raise error when all params are facetable" do
          V1::Schema::Field.any_instance.stub(:facetable?) { true }
          expect {
            subject.validate_params(['title'])
          }.not_to raise_error BadRequestSearchError
        end
        it "does not raise error when params is empty" do
          expect {
            subject.validate_params([])
          }.not_to raise_error BadRequestSearchError
        end
        context "date facets" do
          it "does not raise error for a valid temporal date facet" do
            subject.validate_params(['temporal.start'])
            expect {
              subject.validate_params(['temporal.start'])
            }.not_to raise_error BadRequestSearchError
          end
          it "does not raise error for a valid temporal date facet and interval" do
            expect {
              subject.validate_params(['temporal.start.month'])
            }.not_to raise_error BadRequestSearchError
          end
          it "does not raise error for a valid date facet and interval" do
            expect {
              subject.validate_params(['created.year'])
            }.not_to raise_error BadRequestSearchError
          end
          it "raises an error for a valid date facet and an invalid interval/trailing-junk" do
            expect {
              subject.validate_params(['created.invalid_interval_name'])
            }.to raise_error BadRequestSearchError
          end
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

      describe "#facet_type" do
        it "returns 'date' for date-mapped fields" do
          V1::Schema.stub(:flapping) { stub(:type => 'date') }
          expect(subject.facet_type('some_date')).to eq 'date'
        end
        
        it "returns 'terms' for string-mapped fields" do
          V1::Schema.stub(:flapping) { stub(:type => 'string') }
          expect(subject.facet_type('some_string')).to eq 'terms'
        end

        it "returns 'terms' for any field with an unrecognized mapping" do
          V1::Schema.stub(:flapping) { stub(:type => 'integer') }
          expect(subject.facet_type('some_number')).to eq 'terms'
        end
      end

      describe "#facet_field" do
        it "translates a top level field" do
          V1::Schema.stub(:flapping) { stub(:type => 'string', :multi_fields => []) }
          expect(subject.facet_field('title')).to eq 'title'
        end
        it "translates a multi_field field with no .raw subfields" do
          V1::Schema.stub(:flapping) { stub(:type => 'string', :multi_fields => []) }
          expect(subject.facet_field('field1.name')).to eq 'field1.name'
        end
        it "translates a multi_field field with a .raw subfield" do
          raw_field = stub(:name => 'raw', :facetable? => true)
          V1::Schema.stub(:flapping) { stub(:type => 'string', :multi_fields => [raw_field]) }
          expect(subject.facet_field('isPartOf.name')).to eq 'isPartOf.name.raw'
        end
      end



    end

  end

end
