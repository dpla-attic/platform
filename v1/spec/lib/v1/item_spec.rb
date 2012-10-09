require 'v1/item'

module Rails; end

module V1

  describe Item do

    before(:each) do
      stub_const("V1::Config::SEARCH_INDEX", "some_index")
      Rails.stub_chain(:logger, :debug) { stub }
    end

    describe "#fetch" do

      it "delegates to V1::Repository.fetch" do
        id = stub
        V1::Repository.should_receive(:fetch).with(id)
        subject.fetch(id)
      end

    end

    describe "#search" do
      let(:search) { mock('search').as_null_object }
      let(:query) { mock('query').as_null_object }

      it "uses V1::Config::SEARCH_INDEX for its search index" do
        Tire::Search::Search.should_receive(:new).with(V1::Config::SEARCH_INDEX) { search }
        params = {'q' => 'banana'}
        subject.search(params)
      end

      context "when there are no search params" do
        #it "should not call search.query"
        #it "should return global facets?"
      end        

      context "when searching by keyword" do

        it "searches on the 'q' param as a string" do
          params = {'q' => 'banana'}
          Tire::Search::Search.stub(:new) { search }
          search.stub(:query) { stub }

          query.should_receive(:string).with(params['q'])
          search.should_receive(:query).and_yield( query )
          
          subject.search(params)
        end

        it "returns search.results()" do
          params = {'q' => 'banana'}
          Tire::Search::Search.stub(:new) { search }
          search.stub(:query) { stub }

          results = stub("results")
          search.stub(:results) { results }

          search.should_receive(:results) { results }
          expect(subject.search(params)).to eq results
        end

      end

      context "when searching by a specific field" do
        it "restricts its search to that field" do
          params = {'title' => 'banana'}
          stub_const("V1::Item::SEARCHABLE_FIELDS", %w( title ))
          Tire::Search::Search.stub(:new) { search }
          search.stub(:query) { stub }

          query.should_receive(:string).with( "title:" + "banana")
          search.should_receive(:query).and_yield( query )
          subject.search(params)
         end
        
        it "raises an error for invalid fields" do
          params = {'fakefield' => 'lol'}
          stub_const("V1::Item::SEARCHABLE_FIELDS", %w( title ))
          Tire::Search::Search.stub(:new) { search }
          search.stub(:query) { stub }

          query.should_not_receive(:string).with( "fakefield:" + "lol")
          search.stub(:query).and_yield( query )
          subject.search(params)
        end
      end

    end

  end

end
