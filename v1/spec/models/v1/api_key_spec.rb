require_relative '../../../app/models/v1/api_key'

module V1

  describe ApiKey do
    
    let(:owner) { 'key-email@dp.la' }
    let(:db) { double } 
    let(:test_params) { { 'db' => db, 'owner' => owner } }
    let(:test_key_id) { '2db038dfbbb42b9bd6ae6797e119eecc' }
    
    before(:each) do
      ApiKey.any_instance.stub(:generate_key_id) { test_key_id }
    end

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

      it "returns an active (AKA 'non-disabled') key correctly" do
        found_key_attrs = {
          'db' => db,
          'id' => test_key_id,
          '_rev' => '123abc',
          'owner' => owner,
        }
        db.should_receive(:get).with(test_key_id) { found_key_attrs }
        key = ApiKey.find_by_key(db, test_key_id)
        expect(key.disabled?).to be_false
      end

      it "returns a disabled key correctly" do
        found_key_attrs = {
          'db' => db,
          'id' => test_key_id,
          '_rev' => '123abc',
          'owner' => owner,
          'disabled' => true,
        }
        db.should_receive(:get).with(test_key_id) { found_key_attrs }
        key = ApiKey.find_by_key(db, test_key_id)
        expect(key.disabled?).to be_true
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
        }.to raise_error Errno::ECONNREFUSED
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
    
    describe "to_hash" do

      it "creates the expected structure" do
        key = ApiKey.new(test_params)
        expect(key.to_hash)
          .to eq({
                   '_id' => test_key_id,
                   'owner' => owner,
                   'created_at' => nil,
                   'updated_at' => nil,
                 })
      end

    end

    describe "#save" do

      before(:each) do
        ApiKey.any_instance.stub(:build_timestamp) { 'faketimestamp' }
      end
      
      it "delegates to its db and passes itself as a hash" do
        key = ApiKey.new(test_params)
        db.should_receive(:save_doc)
        key.save
      end

      it "sets the timestamps correctly for a new instance" do
        key = ApiKey.new(test_params)
        internal_hash = {
          '_id' => test_key_id,
          'owner' => test_params['owner'],
          'created_at' => 'faketimestamp',
          'updated_at' => 'faketimestamp',
        }

        db.should_receive(:save_doc).with(internal_hash)
        key.save
      end

      it "updates updated_at, but not created_at, when saving an existing instance a 2nd time" do
        db.stub(:save_doc)
        key = ApiKey.new(test_params)
        key.save
        first_created = key.created_at
        first_updated = key.updated_at
        
        key.stub(:build_timestamp) { 'NEWtimestamp' }
        key.save
        expect(key.created_at).to eq first_created
        expect(key.updated_at).to eq 'NEWtimestamp'
        
        # expect(false).to be_true
        # key_hash = key.to_hash
        # puts "HK: #{key_hash}"
        
        # ApiKey.any_instance.stub(:build_timestamp) { 'NEWtimestamp' }
        # key_hash = {
        #   'id' => test_key_id,
        #   '_rev' => '123abc',
        #   'owner' => test_params['owner'],
        #   'created_at' => 'oldtimestamp',
        #   'updated_at' => 'oldtimestamp',
        # }

        # expected_hash = key_hash.merge({'updated_at' => 'NEWtimestamp'})
        # puts "EH: #{expected_hash}"
        # db.should_receive(:save_doc).with(expected_hash)
        # key.save
      end

    end

    #TODO: move these to ApiKey model unit tests
    # let(:key_id) { '6c30d962ed96c45c7f007635ef011354' }
    # let(:active_key) { {'_id' => key_id} }
    # let(:disabled_key) { {'_id' => key_id, 'disabled' => true} }

    # it "returns false for a key not in hex format" do
    #   expect(subject.authenticate_api_key('`cat /etc/passwd`')).to be_false
    # end
    # it "returns false for a key that does not exists" do
    #   subject.stub_chain(:database, :get) { raise RestClient::ResourceNotFound }
    #   expect(subject.authenticate_api_key(key_id)).to be_false
    # end
    # it "returns false for a key that exists but is disabled" do
    #   subject.stub_chain(:database, :get) { disabled_key }
    #   expect(subject.authenticate_api_key(key_id)).to be_false
    # end
    # it "returns true for an existing key that is not disabled" do
    #   subject.stub_chain(:database, :get) { active_key }
    #   expect(subject.authenticate_api_key(key_id)).to be_true
    # end
    # it "allows a connection refused exception to bubble up if one is raised" do
    #   subject.stub_chain(:database, :get) { raise Errno::ECONNREFUSED }
    
    #   expect {
    #     subject.authenticate_api_key(key_id)
    #   }.to raise_error Errno::ECONNREFUSED
    # end

    describe "#authenticate" do

      it "returns false for keys with an invalid format" do
        ApiKey.should_not_receive(:find_by_key)
        expect(ApiKey.authenticate(db, '; drop table users')).to be_false
      end
      
      it "returns true for keys that are not disabled" do
        ApiKey.should_receive(:find_by_key).with(db, test_key_id) { double(:disabled? => false) }
        expect(ApiKey.authenticate(db, test_key_id)).to be_true
      end
      
      it "returns false for disabled keys" do
        ApiKey.should_receive(:find_by_key).with(db, test_key_id) { double(:disabled? => true) }
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

