require 'v1/search'

module V1

  describe Search do

    context "#get_search_config" do 

      it "should raise an exception when the elasticsearch_pointer yml file is missing" do
        File.stub(:expand_path) { './non existent pointer file' }
        expect do
          Search.get_search_config
        end.to raise_exception /missing or invalid/i
      end

    end

    context "#get_search_endpoint" do
      context "when the expected elasticsearch.yml does not exist"
      it "should raise exception" do
        Search.stub(:get_search_config) { './non existent elasticsearch.yml' } 

        expect do
          Search.get_search_endpoint
        end.to raise_exception /missing elasticsearch.yml/i
      end
    end

    context "when the expected elasticsearch.yml does exist" do
      it "should construct the correct elasticsearch URL based on explicit values in elasticsearch.yml" do
        config_values = {
          'network.host' => 'testhost',
          'http.port' => '9999'          
        }
        Search.stub(:get_search_config)
        YAML.stub(:load_file) { config_values }
        Search.get_search_endpoint.should == "http://testhost:9999/"
      end

      it "should construct the correct elasticsearch URL based on some defaults" do
        config_values = {}
        Search.stub(:get_search_config)
        YAML.stub(:load_file) { config_values }
        Search.get_search_endpoint.should == "http://0.0.0.0:9200/"
      end
    end
  end
end
