require_relative '../../../app/models/v1/api_key'

module V1
  
  describe ApiKey do
    let(:owner) { 'key-email@dp.la' }
    let(:db) { double } 
    let(:test_params) { { 'db' => db, 'owner' => owner } }
    let(:test_key_id) { '2db038dfbbb42b9bd6ae6797e119eecc' }
    
    describe "#initialize" do

      it "sets its db attr" do
        expect(ApiKey.new( test_params ).db).to eq db
      end

      it "sets its owner " do
        expect(ApiKey.new( test_params ).owner).to eq owner
      end

      it "sets its disabled attr by default" do
        expect(ApiKey.new( test_params ).disabled).to be_false
      end

      it "sets its disabled attr when specified" do
        expect(ApiKey.new( test_params.merge('disabled' => true) ).disabled).to be_true
      end

      it "creates a valid key id" do
        SecureRandom.stub(:hex).with(16) { test_key_id }
        expect(ApiKey.new( test_params ).id).to eq test_key_id
      end

      it "raises an exception for a missing owner param" do
        expect {
          ApiKey.new( 'db' => db )
        }.to raise_error /Missing 'owner' param/i
      end

      it "lowercases an address and removes periods from Gmail-ish usernames" do
        key = ApiKey.new( test_params.merge('owner' => 'FOO.BAR@gmail.com') )
        expect(key.owner).to eq 'foobar@gmail.com'
      end

      it "lowercases an address and does not remove periods from a non Gmail-ish usernames" do
        key = ApiKey.new( test_params.merge('owner' => 'doodle.BUG@bug.com') )
        expect(key.owner).to eq 'doodle.bug@bug.com'
      end

    end
    
    describe "#find_by_key" do

      it "delegates to its db with the correct params" do
        key_id = '2db038dfbbb42b9bd6ae6797e119eecc'
        db = double
        db.should_receive(:get).with(key_id)
        ApiKey.find_by_key(db, key_id)
      end

      it "returns nil if a key is not found" do
        db = double
        db.should_receive(:get).with(test_key_id).and_raise RestClient::ResourceNotFound
        expect(ApiKey.find_by_key(db, test_key_id)).to be_false
      end

      it "lets Errno::ECONNREFUSED exceptions bubble up" do
        db = double
        db.stub(:get).and_raise Errno::ECONNREFUSED
        expect {
          ApiKey.find_by_key(db, test_key_id)
        }.to raise_error 
      end
      
    end
    
    describe "#find_by_owner" do
      it "returns the correct data from a key it finds" do
        owner = 'foo@bar.com'
        found_key = {'value' => 'found_key_id'}
        db = double
        ApiKey.should_receive(:sanitize_email).with(owner) { owner }
        key = db.should_receive(:view)
          .with('api_auth_utils/find_by_owner', 'key' => owner)  {
          { 'rows' => [found_key] }
        }
        expect(ApiKey.find_by_owner(db, owner)).to eq 'found_key_id'
      end
    end
    

    describe "#save" do

      it "delegates to its db and passes itself as a hash" do
        db = double
        key = ApiKey.new('db' => db, 'owner' => 'a@b.com')
        db.should_receive(:save_doc).with(key.to_hash)
        key.save

      end
    end

    describe "to_hash" do
      
      before :each do
        SecureRandom.stub(:hex).with(16) { test_key_id }
      end

      it "creates the expected structure when disabled is false" do
        key = ApiKey.new test_params
        expect(key.to_hash).to eq( { '_id' => test_key_id, 'owner' => owner } )
      end

      it "creates the expected structure when disabled is true" do
        key = ApiKey.new test_params.merge('disabled' => true)
        expect(key.to_hash).to eq( { '_id' => test_key_id, 'owner' => owner, 'disabled' => true } )
      end
      
    end

    describe "#authenticate" do
      let(:db) { double }

      it "returns false for keys with an invalid format" do
        ApiKey.should_not_receive(:find_by_key)
        expect(ApiKey.authenticate(db, '; drop table users')).to be_false
      end
      
      it "calls find_by_key with the correct params" do
        ApiKey.should_receive(:find_by_key).with(db, test_key_id) { {} }
        ApiKey.authenticate(db, test_key_id)
      end
      
      it "returns true for keys that are not disabled" do
        ApiKey.should_receive(:find_by_key).with(db, test_key_id) { {'disabled' => false} }
        expect(ApiKey.authenticate(db, test_key_id)).to be_true
      end
      
      it "returns false for disabled keys" do
        ApiKey.should_receive(:find_by_key).with(db, test_key_id) { {'disabled' => true} }
        expect(ApiKey.authenticate(db, test_key_id)).to be_false
      end
      
      it "returns false for non-existent keys" do
        ApiKey.should_receive(:find_by_key).with(db, test_key_id)
        expect(ApiKey.authenticate(db, test_key_id)).to be_false
      end

    end

    describe "#disable" do

      it "sets the disabled attr to true" do
        key = ApiKey.new( test_params )
        key.disable
        expect(key.disabled).to be_true
      end
      
    end
    
    describe "#enable" do
      
      it "sets the disabled attr to false" do
        key = ApiKey.new( test_params.merge('disabled' => true) )
        key.enable
        expect(key.disabled).to be_false
      end
      
    end

  end
  
end
