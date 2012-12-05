require 'v1/searchable/facet'

module V1

  module Searchable

    describe Facet do      
      
      describe "#build_all" do
        it "returns true if it created any facets"
        it "returns false if it created zero facets" do
          expect(subject.build_all(stub, {}, false)).to be_false
        end
        
        it "handles a comma separated list of specific facets to build"
        it "passes the correct global boolean option to the facet method"
        it "defaults to global=false if no option is passed"
        it "calls the search.facet block with the correct params"
        it "translates multi_field facets correctly" do
          
        end
      end

      describe "#validate_params" do
        it "does not raise error when all params are facetable" do
          V1::Schema.stub(:facetable?) { true }
          expect {
            subject.validate_params(['title'])
          }.not_to raise_error BadRequestSearchError
        end
        it "raises an error when any of the params are not facetable" do
          V1::Schema.stub(:facetable?).with('item', 'title') { true }
          V1::Schema.stub(:facetable?).with('item', 'description') { false }
          expect {
            subject.validate_params(['title', 'description'])
          }.to raise_error BadRequestSearchError, /invalid field/i
        end
        it "does not raise error when params is empty" do
          expect {
            subject.validate_params([])
          }.not_to raise_error BadRequestSearchError
        end

      end

      describe "#facet_type" do
        it "returns :date for date-mapped fields" do
          field = 'datefield'
          V1::Schema.should_receive(:item_mapping).with(field) { {:type => 'date'} }
          expect(subject.facet_type(field)).to eq :date
        end
        
        it "returns :terms for string-mapped fields" do
          field = 'stringfield'
          V1::Schema.should_receive(:item_mapping).with(field) { {:type => 'string'} }
          expect(subject.facet_type(field)).to eq :terms
        end

        it "returns :terms for any field with an unrecognized mapping" do
          field = 'dynamicfield'
          V1::Schema.should_receive(:item_mapping).with(field) { {:type => 'whoknows'} }
          expect(subject.facet_type(field)).to eq :terms
        end

      end

    end

  end

end
