require 'v1/config'

module V1

  describe Config do

    describe "Constants" do
      it "has the correct SEARCH_INDEX value" do
        expect(V1::Config::SEARCH_INDEX).to eq 'dpla'
      end

      it "has the correct REPOSITORY_DATABASE value" do
        expect(V1::Config::REPOSITORY_DATABASE).to eq 'dpla'
      end
    end

    describe "#enable_tire_logging" do
      it "should receive a configure call (loose test)" do
        Tire.should_receive(:configure)
        subject.enable_tire_logging('env_string')
      end
    end
    
    describe "#dpla" do
      context "when the dpla config file does not exist" do
        it "it raises an error" do
          File.stub(:expand_path) { '/wrong path' }
          File.stub(:exists?).with('/wrong path') { false }
          expect {
            subject.dpla
          }.to raise_error /No config file found at.*/i
        end
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

  end

end
