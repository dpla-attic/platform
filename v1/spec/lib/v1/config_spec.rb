require 'v1/config'

module V1

  describe Config do

    before(:each) do
      # clear memoized var
      subject.instance_variable_set(:@dpla_config, nil)
    end

    describe "Constants" do
      it "has the correct REPOSITORY_DATABASE value" do
        expect(V1::Config::REPOSITORY_DATABASE).to eq 'dpla'
      end
    end

    describe "#search_index" do
      it "returns the search_index defined in the config file" do
        subject.stub(:dpla) { {'search' => {'index_name' => "foo"}} }
        expect(subject.search_index).to eq 'foo'        
      end
      
      it "supplies the correct default value" do
        subject.stub(:dpla) { {'search' => {}} }
        expect(subject.search_index).to eq 'dpla'
      end
    end

    describe "#configure_search_logging" do
      it "should configure the Tire logger" do
        Tire::Configuration.should_receive(:logger)
        subject.configure_search_logging('env_string')
      end
    end
    
    describe "#dpla" do
      it "returns existing config file parsed as yaml" do
        yaml = double
        f = File.expand_path("../../../../config/dpla.yml", __FILE__)
        YAML.should_receive(:load_file).with(f) { yaml }
        expect(subject.dpla).to eq yaml
      end
    end

    describe "#search_endpoint" do
      it "returns the search endpoint with leading 'http://' if an endpoint is defined" do
        subject.stub(:dpla) { {'search' => {'endpoint' => "testhost:9999"}} }
        expect(Config.search_endpoint).to eq "http://testhost:9999"
      end

      it "returns the default search endpoint if one is not defined" do
        subject.stub(:dpla) { {} }
        expect(Config.search_endpoint).to eq "http://127.0.0.1:9200"
      end
    end

    describe "#accept_any_api_key?" do
      it "returns false when no setting is present" do
        subject.stub(:dpla) { {} }
        expect(subject.accept_any_api_key?).to be_false
      end
      it "returns false when the setting is present and set to false" do
        subject.stub(:dpla) { {'allow_all_keys' => false} }
        expect(subject.accept_any_api_key?).to be_false
      end
      it "returns false when the setting is present but not set to a valid true value" do
        subject.stub(:dpla) { {'allow_all_keys' => 'off'} }
        expect(subject.accept_any_api_key?).to be_false
      end
      it "returns true when the setting is present and set to true" do
        subject.stub(:dpla) { { 'api_auth' => {'allow_all_keys' => true}} }
        expect(subject.accept_any_api_key?).to be_true
      end
    end

    describe "#skip_key_auth_completely?" do
      it "returns false when no setting is present" do
        subject.stub(:dpla) { {} }
        expect(subject.skip_key_auth_completely?).to be_false
      end
      it "returns false when the setting is present and set to false" do
        subject.stub(:dpla) { {'skip_key_auth_completely' => false} }
        expect(subject.skip_key_auth_completely?).to be_false
      end
      it "returns false when the setting is present but not set to a valid true value" do
        subject.stub(:dpla) { {'skip_key_auth_completely' => 'off'} }
        expect(subject.skip_key_auth_completely?).to be_false
      end
      it "returns true when the setting is present and set to true" do
        subject.stub(:dpla) { { 'api_auth' => {'skip_key_auth_completely' => true}} }
        expect(subject.skip_key_auth_completely?).to be_true
      end
    end

    describe "#initialize_search_engine" do
      it "sets url and wrapper options" do
        Tire::Configuration.should_receive(:url).with(subject.search_endpoint)
        Tire::Configuration.should_receive(:wrapper).with(Hash)
        subject.initialize_search_engine
      end
    end

    describe "#email_from_address" do
      it "supplies correct default" do
        subject.stub(:dpla) { {} }
        expect(subject.email_from_address).to eq 'dpla_default_sender@example.com'
      end
      it "pulls correct value from the config" do
        subject.stub(:dpla) { {'api' => {'email_from_address' => 'me@dp.la'}} }
        expect(subject.email_from_address).to eq 'me@dp.la'
      end
    end

    describe "#cache_results" do
      it "supplies correct default" do
        subject.stub(:dpla) { {} }
        expect(subject.cache_results).to be_false
      end
      it "pulls correct value from the config" do
        subject.stub(:dpla) { {'caching' => {'cache_results' => true}} }
        expect(subject.cache_results).to be_true
      end
    end

    describe "#cache_store" do
      it "returns null_store when caching is disabled" do
        subject.stub(:cache_results) { false }
        expect(subject.cache_store).to eq :null_store
      end
      it "returns dalli_store params when requested" do
        subject.stub(:cache_results) { true }
        subject.stub(:dpla) { {
            'caching' => {
              'store' => 'dalli_store',
              'memcache_servers' => ['memcache1']
            }
          } }
        expect(subject.cache_store).to eq [:dalli_store, "memcache1", {:namespace=>"V2", :compress=>true}]
      end
      it "raises exception when dalli_store requested but no memcacheservers specified" do
        subject.stub(:cache_results) { true }
        subject.stub(:dpla) { {
            'caching' => {
              'store' => 'dalli_store'
            }
          } }
        expect {
          subject.cache_store
        }.to raise_error /No memcache servers specified for cache_store: dalli_store/i
      end
      it "returns file_store params when requested" do
        subject.stub(:cache_results) { true }
        subject.stub(:dpla) { {
            'caching' => {
              'store' => 'file_store'
            }
          } }
        expect(subject.cache_store).to eq [:file_store, "tmp/api-cache"]
      end

    end

  end

end
