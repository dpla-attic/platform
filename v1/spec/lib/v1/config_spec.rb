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

    end

    context "#search_endpoint" do

      it "returns the search endpoint if one is defined" do
        Config.stub(:dpla) {
          {
            'search' => { 'endpoint' => "testhost:9999" }
          }
        }
        expect(Config.search_endpoint).to eq "http://testhost:9999"
      end

      it "returns the default search endpoint if one is not defined" do
        Config.stub(:dpla) { {} }
        expect(Config.search_endpoint).to eq "http://127.0.0.1:9200"
      end

    end

  end

end
