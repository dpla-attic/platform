require 'v1/api_auth'

module V1

  describe ApiAuth do
  
    context "API keys" do

      describe "#authenticate_api_key" do

        it "delegates to the ApiKey model" do
          key_id = '6c30d962ed96c45c7f007635ef011354'
          subject.stub(:auth_database) { 'boop' }
          ApiKey.should_receive(:authenticate).with('boop', key_id)
          subject.authenticate_api_key(key_id)
        end

      end

      describe "#auth_database" do
        it "delegates to correct Repository method" do
          Repository.should_receive(:admin_cluster_auth_database) { 'repo_auth_db' }
          expect(subject.auth_database).to eq 'repo_auth_db'
        end
      end

      describe "#show_api_auth" do
        it "correctly handles an ApiKey instance" do
          key = double(:disabled? => true)
          expect(subject.show_api_auth(key)).to eq key
        end

        it "delegates correctly when passed a key_id" do
          key_id = '6c30d962ed96c45c7f007635ef011354'
          ApiKey.should_receive(:find_by_key).with(anything(), key_id) { 'foundkey' }
          expect(subject.show_api_auth(key_id)).to eq 'foundkey'
        end

        it "delegates correctly when passed an owner" do
          key_id = 'user@example.com'
          ApiKey.should_receive(:find_by_owner).with(anything(), key_id) { 'foundkey' }
          expect(subject.show_api_auth(key_id)).to eq 'foundkey'
        end

        it "returns error message string for unrecognizable input" do
          key_id = 'somejunk text'
          expect(subject.show_api_auth(key_id)).to match /does not look like a key or an owner/
        end
      end
  
      describe "#create_api_key" do
        it "creates a new ApiKey correctly" do
          db = double
          owner = double
          subject.stub(:auth_database) { db }
          key_stub = double
          key_stub.should_receive(:save)
          
          ApiKey.should_receive(:new).with( {'db' => db, 'owner' => owner} ) { key_stub }
          expect(subject.create_api_key(owner)).to eq key_stub
        end
        
      end

    end

  end

end
