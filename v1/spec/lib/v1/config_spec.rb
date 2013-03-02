require 'v1/config'

module V1

  describe Config do
    context "Constants" do

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
          File.stub(:exists?).with('/wrong path') { false }
          expect {
            Config.dpla
          }.to raise_error /No config file found at.*/i
        end
      end

      context "when the dpla config file exists but is missing required keys" do
        it "should raise an error" do
          File.stub(:expand_path) { 'dpla.yml' }
          File.stub(:exists?).with('dpla.yml') { true }
          YAML.stub(:load_file) { {'some_key' => 'abc'} }
          expect {
            Config.dpla
          }.to raise_error /Missing required values in:.*/i
        end
      end

      context "when the dpla config file includes all valid section headers" do
        it "returns the hash of config values" do
          File.stub(:expand_path) { 'dpla.yml' }
          File.stub(:exists?).with('dpla.yml') { true }
          YAML.stub(:load_file) { {'read_only_user' => 'abc', 'search' => 'abc', 'repository' => 'abc'} }
          expect( Config.dpla.keys ).to match_array %w( read_only_user repository search )
        end

        it "gracefully handles non-required fields while still requiring the required fields" do
          File.stub(:expand_path) { 'dpla.yml' }
          File.stub(:exists?).with('dpla.yml') { true }
          YAML.stub(:load_file) {
            {
              'read_only_user' => 'abc',
              'extra_key' => 'value',
              }
          }
          expect( Config.dpla.keys ).to match_array %w( read_only_user extra_key )
        end

      end
    end

    context "#search_endpoint" do

      it "constructs the correct elasticsearch URL based on explicit values in elasticsearch.yml" do
        Config.stub(:dpla) {
          {
            'search' => { 'endpoint' => "http://testhost:9999" }
          }
        }
        expect(Config.search_endpoint).to eq "http://testhost:9999"
      end

      it "handles an empty elasticsearch.yml by supplying default values" do
        Config.stub(:dpla) {
          {
            'somekey' => 'someval'
          }
        }
        expect(Config.search_endpoint).to eq "http://0.0.0.0:9200"
      end

    end

  end

end
