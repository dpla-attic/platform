require 'v1/config'

module V1

  describe Config do
    context "Constants" do
      #TODO: move these to their more specific modules
      it "has the correct SEARCH_INDEX value" do
        expect(V1::Config::SEARCH_INDEX).to eq 'dpla'
      end

      it "has the correct REPOSITORY_DATABASE value" do
        expect(V1::Config::REPOSITORY_DATABASE).to eq 'dpla'
      end

    end
    
    describe "#dpla" do
      context "when the dpla config file does not exist" do
        it "it raises an error" do
          File.stub(:expand_path) { '/wrong path' }
          File.should_receive(:exists?).with('/wrong path') { false }
          expect do
            Config.dpla
          end.to raise_error /No DPLA config file found at.*/i
        end
      end

      context "when the dpla config file exists but is mal-formed" do
        it "should raise an error" do
          File.stub(:expand_path) { '/dpla.yml' }
          File.should_receive(:exists?).with('/dpla.yml') { true }
          YAML.stub(:load_file) { {'no_ES' => 'abc', 'no_cdb' => 'abc'} }
          expect do
            Config.dpla
          end.to raise_error /The DPLA config file found at .* is lacking needed values/i
        end
      end

      context "when the dpla config file includes all valid section headers" do
        it "returns the hash of config values" do
          File.stub(:expand_path) { '/dpla.yml' }
          File.should_receive(:exists?).with('/dpla.yml') { true }
          YAML.stub(:load_file) { {'couch_read_only' => 'abc', 'couch_admin' => 'abc'} }
          expect(Config.dpla).to have_key("couch_read_only") && have_key("couch_admin")
        end

      end
    end



    describe "#get_search_config" do

      context "when the custom elasticsearch config files are set up correctly" do
        it "returns the existing file from elasticsearch_pointer.yml" do
          File.stub(:expand_path) { '/existing_pointer_file.yml' }
          File.should_receive(:exist?).with('/existing_pointer_file.yml') { true }
          File.should_receive(:exist?).with('elasticsearch.yml') { true }
          YAML.stub(:load_file) { {'config_file' => 'elasticsearch.yml'} }
          expect(Config.get_search_config).to eq 'elasticsearch.yml'
        end
      end

      context "when elasticsearch_pointer.yml is missing" do

        context "and the default '/etc/elasticsearch/elasticsearch.yml' exists" do
          it "checks for default elasticsearch.yml and return it" do
            File.stub(:expand_path) { '/non existent pointer file' }
            File.should_receive(:exist?).with('/non existent pointer file') { false }
            File.should_receive(:exist?).with('/etc/elasticsearch/elasticsearch.yml') { true }
            expect(Config.get_search_config).to eq '/etc/elasticsearch/elasticsearch.yml'
          end
        end

        context "and the default '/etc/elasticsearch/elasticsearch.yml' does not exist" do
          it "raises an error" do
            File.stub(:expand_path) { '/non existent pointer file' }
            File.should_receive(:exist?).with('/non existent pointer file') { false }
            File.should_receive(:exist?).with('/etc/elasticsearch/elasticsearch.yml') { false }
            expect do
              Config.get_search_config
            end.to raise_error /missing elasticsearch pointer file.* and no default/i
          end
        end

      end

      context "when elasticsearch_pointer.yml points to an invalid location" do

        it "raises an error" do
          File.stub(:expand_path) { 'elasticsearch_pointer.yml' }
          File.should_receive(:exist?).with('elasticsearch_pointer.yml') { true }
          YAML.stub(:load_file) { {'config_file' => 'wrong_elasticsearch.yml'} }
          File.should_receive(:exist?).with('wrong_elasticsearch.yml') { false }

          expect do
            Config.get_search_config
          end.to raise_error /invalid path/i
        end

      end

    end


    context "#get_search_endpoint" do

      it "constructs the correct elasticsearch URL based on explicit values in elasticsearch.yml" do
        config_values = {
          'network.host' => 'testhost',
          'http.port' => '9999'
        }
        Config.stub(:get_search_config)
        YAML.stub(:load_file) { config_values }

        Config.get_search_endpoint.should == "http://testhost:9999"
      end

      it "handles an empty elasticsearch.yml by supplying default values" do
        Config.stub(:get_search_config)
        YAML.stub(:load_file) { false }
        expect(Config.get_search_endpoint).to eq "http://0.0.0.0:9200"
      end

    end

  end
  
  

end
