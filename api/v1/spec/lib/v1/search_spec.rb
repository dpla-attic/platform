require 'v1/search'

module V1

  describe Search do

    describe "#get_search_config" do

      context "when the custom elasticsearch config files are set up correctly" do
        it "should return the existing file from elasticsearch_pointer.yml" do
          File.stub(:expand_path) { '/existing_pointer_file.yml' }
          File.should_receive(:exist?).with('/existing_pointer_file.yml') { true }
          File.should_receive(:exist?).with('elasticsearch.yml') { true }
          YAML.stub(:load_file) { {'config_file' => 'elasticsearch.yml'} }
          Search.get_search_config.should == 'elasticsearch.yml'
        end
      end
#       <File (class)> received :exist? with unexpected arguments
#         expected: ("/existing_pointer_file.yml")
#              got: ("/home/phunk/camp15/api/v1/config/elasticsearch/elasticsearch_pointer.yml")
     # /home/phunk/camp15/api/v1/lib/v1/search.rb:12:in `get_search_config'
     # ./search_spec.rb:15:in `block (4 levels) in <module:V1>'

      context "when elasticsearch_pointer.yml is missing" do

        context "and the default '/etc/elasticsearch/elasticsearch.yml' exists" do
          it "should check for default elasticsearch.yml and return it" do
            File.stub(:expand_path) { '/non existent pointer file' }
            File.should_receive(:exist?).with('/non existent pointer file') { false }
            File.should_receive(:exist?).with('/etc/elasticsearch/elasticsearch.yml').twice() { true }
            Search.get_search_config.should == '/etc/elasticsearch/elasticsearch.yml'
          end
        end

        context "and the default '/etc/elasticsearch/elasticsearch.yml' does not exist" do
          it "should raise an error" do
            File.stub(:expand_path) { '/non existent pointer file' }
            File.should_receive(:exist?).with('/non existent pointer file') { false }
            File.should_receive(:exist?).with('/etc/elasticsearch/elasticsearch.yml') { false }
            expect do
              Search.get_search_config
            end.to raise_error /missing elasticsearch pointer file.* and no default/i
          end
        end

      end

      context "when elasticsearch_pointer.yml points to an invalid location" do

        it "should raise an error" do
          File.stub(:expand_path) { 'elasticsearch_pointer.yml' }
          File.should_receive(:exist?).with('elasticsearch_pointer.yml') { true }
          YAML.stub(:load_file) { {'config_file' => 'wrong_elasticsearch.yml'} }
          File.should_receive(:exist?).with('wrong_elasticsearch.yml') { false }

          expect do
            Search.get_search_config
          end.to raise_error /invalid path/i
        end
        
      end

    end
    

    context "#get_search_endpoint" do

      it "should construct the correct elasticsearch URL based on explicit values in elasticsearch.yml" do
        config_values = {
          'network.host' => 'testhost',
          'http.port' => '9999'          
        }
        Search.stub(:get_search_config)
        YAML.stub(:load_file) { config_values }

        Search.get_search_endpoint.should == "http://testhost:9999"
      end

      it "should handle an empty elasticsearch.yml by supplying default values" do
        Search.stub(:get_search_config)
        YAML.stub(:load_file) { false }
        Search.get_search_endpoint.should == "http://0.0.0.0:9200"
      end

    end
    
  end

end
