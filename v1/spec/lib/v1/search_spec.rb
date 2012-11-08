require 'v1/search'

module V1

  module Search

    describe "#build_facets" do
      #it "handles the '*' wildcard for all facets"
      it "gracefully degrades when the '*' wildcard facet is requested" do
        expect {
          V1::Search.build_facets(stub, {:facets => '*'})
        }.to_not raise_error
      end
      
      it "returns true if it created any facets"
      it "returns false if it created zero facets" do
        expect(V1::Search.build_facets(stub, {:facets => '*'})).to be_false
      end
      
      
      it "handles a comma separated list of specific facets to build"
      it "passes the global boolean option to the facet method"
      it "defaults to global=false if no option is passed"
      it "calls the search.facet block with the correct params"
      it "requests the correct type of facet from its search object"
    end

    describe "#facet_type" do
      it "returns :date for date-mapped fields" do
        field = 'datefield'
        V1::Schema.should_receive(:item_mapping).with(field) { {:type => 'date'} }
        expect(V1::Search.facet_type(field)).to eq :date
      end
      
      it "returns :terms for string-mapped fields" do
        field = 'stringfield'
        V1::Schema.should_receive(:item_mapping).with(field) { {:type => 'string'} }
        expect(V1::Search.facet_type(field)).to eq :terms
      end

      it "returns :terms for any field with an unrecognized mapping" do
        field = 'dynamicfield'
        V1::Schema.should_receive(:item_mapping).with(field) { {:type => 'whoknows'} }
        expect(V1::Search.facet_type(field)).to eq :terms
      end

    end

  end

end
