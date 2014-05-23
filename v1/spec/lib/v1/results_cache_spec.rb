require 'v1/results_cache'

module V1

  describe ResultsCache do

    let(:klass) { ResultsCache }
    let(:resource) { 'item' }
    # let(:base_params) {  #this is for search|fetch cache_key methods that have not been moved here yet
    #   {
    #     'action' => 'items',
    #     'api_key' => 'abc123',
    #     'controller' => 'some_controller',
    #   }
    # }

    describe ".base_cache_key" do

      it "returns the expected string without a 'key' param" do
        expect(klass.base_cache_key(resource, 'items')).to eq "v2-item-items-d41d8cd98f00b204e9800998ecf8427e"
      end
    
      it "returns the expected string with a string 'key' param" do
        params = {'fields' => 'a,b', 'page_size' => 99}.sort.to_s
        expect(klass.base_cache_key(resource, 'foo', params)).to eq "v2-item-foo-090eccc356fee247b265062c526e8f17"
      end
    
      it "returns the expected string with a hash 'key' param" do
        params = {'fields' => 'a,b', 'page_size' => 99}
        expect(klass.base_cache_key(resource, 'foo', params)).to eq "v2-item-foo-090eccc356fee247b265062c526e8f17"
      end
    
    end

  end

end
