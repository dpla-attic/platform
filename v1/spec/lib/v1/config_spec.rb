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
          end.to raise_error /No config file found at.*/i
        end
      end

      context "when the dpla config file exists but is mal-formed" do
        it "should raise an error" do
          File.stub(:expand_path) { '/dpla.yml' }
          File.should_receive(:exists?).with('/dpla.yml') { true }
          YAML.stub(:load_file) { {'no_ES' => 'abc', 'no_cdb' => 'abc'} }
          expect do
            Config.dpla
          end.to raise_error /Missing proper values in:.*/i
        end
      end

      context "when the dpla config file includes all valid section headers" do
        it "returns the hash of config values" do
          File.stub(:expand_path) { '/dpla.yml' }
          File.should_receive(:exists?).with('/dpla.yml') { true }
          YAML.stub(:load_file) { {'read_only_user' => 'abc', 'search' => 'abc', 'repository' => 'abc'} }
          expect(Config.dpla).to have_key("read_only_user") && have_key("repository") && have_key("search")
        end

      end
    end

    context "#get_search_endpoint" do

      it "constructs the correct elasticsearch URL based on explicit values in elasticsearch.yml" do
        config_values = {
          'search' => { 'endpoint' => "http://testhost:9999" }
        }

        YAML.stub(:load_file) { config_values }

        Config.get_search_endpoint.should == "http://testhost:9999"
      end

      it "handles an empty elasticsearch.yml by supplying default values" do
        config_values = {}
        YAML.stub(:load_file) { config_values }
        expect(Config.get_search_endpoint).to eq "http://0.0.0.0:9200"
      end

    end

  end

end
