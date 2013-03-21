require 'v1/repository'

module V1

  describe Repository do

    describe "#recreate_database!" do
      it "uses correct repository URI to delete and delete" do
        subject.stub(:admin_endpoint_database => 'dbname')
        couchdb = mock
        couchdb.should_receive(:delete!)
        CouchRest.should_receive(:database).with('dbname') { couchdb }

        CouchRest.should_receive(:database!).with('dbname')
        subject.stub(:recreate_users)
        subject.recreate_database!
      end
      
      it "creates reader user and sets up access rules on DB" do
        CouchRest.stub(:database) { stub.as_null_object }
        CouchRest.stub(:database!)
        subject.should_receive(:recreate_users)
        subject.recreate_database!        
      end

    end

    describe "#reformat_results" do
      it "reformats results properly" do
        results = [
                   {
                     "id"=>"A",
                     "key"=>"A",
                     "doc"=>
                     {
                       "_id"=>"A",
                       "_rev"=>"1-A",
                       "id"=>"aaa",
                       "title"=>"title A"
                     }
                   },
                   {
                     "id"=>"B",
                     "key"=>"B",
                     "doc"=>
                     {
                       "_id"=>"B",
                       "_rev"=>"1-B",
                       "id"=>"bbb",
                       "title"=>"title B"
                     }
                   }
                  ]

        expect(subject.reformat_results(results)).to match_array(
          [
           {"_id" => "A", "id"=>"aaa", "title"=>"title A"},
           {"_id" => "B", "id"=>"bbb", "title"=>"title B"}
          ]
        )
      end
    end

    describe "#fetch" do
      let(:db_mock) { mock 'db' }
      let(:couch_doc) { stub 'couch_doc' }
      let(:couch_doc_z) { stub 'couch_doc_z' }
      let(:endpoint_stub) { stub 'endpoint' }
      
      before(:each) do
        subject.stub(:read_only_endpoint) { endpoint_stub }
        CouchRest.stub(:database).with(endpoint_stub) { db_mock }
      end

      it "invokes CouchRest database on valid endpoint" do
        subject.stub(:wrap_results)
        db_mock.stub(:get_bulk) { { "rows" => [stub] } }
        CouchRest.should_receive(:database).with(endpoint_stub) { db_mock }
        subject.fetch("1")
      end

      it "delegates to CouchRest get_bulk() on comma separated string parameters" do
        couch_docs = [couch_doc, couch_doc_z]
        subject.stub(:wrap_results) { couch_docs }
        db_mock.should_receive(:get_bulk).with(["2", "Z"]) { { "rows" => couch_docs } }
        expect(subject.fetch("2,Z")).to match_array couch_docs
      end

      it "delegates to CouchRest get_bulk() on single string parameter" do
        db_mock.should_receive(:get_bulk).with(["2"]) { { "rows" => [] } }
        subject.fetch("2")
      end

      it "delegates to CouchRest get_bulk() method on array of strings parameter" do
        db_mock.should_receive(:get_bulk).with(["2", "a"]) { { "rows" => [] } }
        subject.fetch(["2", "a"])
      end

    end

    describe "#import_data_file" do
      it "calls import_docs with correct params" do
        data_file = stub
        processed_input_file = stub
        V1::StandardDataset.should_receive(:process_input_file).with(data_file, false) { processed_input_file }
        subject.should_receive(:import_docs).with(processed_input_file)
        subject.import_data_file(data_file)
      end
    end

    describe "#import_test_dataset" do
      it "imports test data for all resources" do
        subject.should_receive(:import_data_file).with(V1::StandardDataset::ITEMS_JSON_FILE)
        subject.should_receive(:import_data_file).with(V1::StandardDataset::COLLECTIONS_JSON_FILE)
        subject.import_test_dataset
      end
    end

    describe "#import_docs" do
      it "imports the correct resource type via the admin endpoint" do
        subject.stub(:admin_endpoint_database) { 'admin_endpoint/dbname' }
        couchdb = mock

        CouchRest.should_receive(:database).with("admin_endpoint/dbname") { couchdb }
        docs = [stub]
        couchdb.should_receive(:bulk_save).with(docs)

        subject.import_docs(docs)
      end

      it "raises an Exception if the bulk_save raises a BadRequest exception" do
        subject.stub(:admin_endpoint_database) { 'admin_endpoint/dbname' }
        couchdb = mock
        couchdb.stub(:bulk_save).and_raise RestClient::BadRequest

        CouchRest.stub(:database).with("admin_endpoint/dbname") { couchdb }
        expect {
          subject.import_docs([stub])
        }.to raise_error Exception, /^ERROR/
      end
    end

    describe "#delete_docs" do
      it "delegates to CouchRest with correct params" do
        subject.stub(:admin_endpoint_database) { 'admin_endpoint/dbname' }
        couchdb = mock

        CouchRest.should_receive(:database).with("admin_endpoint/dbname") { couchdb }
        docs = [stub, stub]
        # lazy way to test that it calls delete on all elements of docs array param
        couchdb.should_receive(:delete_doc).with(docs.first)
        couchdb.should_receive(:delete_doc).with(docs.last)

        subject.delete_docs(docs)        
      end
    end

    describe "#recreate_user" do
      
      before :each do
        subject.stub(:admin_endpoint) { 'couchserver' }
        @users_db = mock('db')
        CouchRest.stub(:database).with("#{subject.admin_endpoint}/_users") { @users_db }
        @read_only_user = mock('ro_user')
      end

      it "should delete any existing read-only users" do
        @users_db.stub(:get).with("org.couchdb.user:user") { @read_only_user }
        @users_db.should_receive(:delete_doc).with(@read_only_user)
        @users_db.stub(:save_doc) { {'ok' => true} }
        subject.recreate_user('user', 'pw')
      end

      it "creates a user" do
        @users_db.stub(:get).with("org.couchdb.user:user") { nil }
        @users_db.should_not_receive(:delete_doc)
        @users_db.should_receive(:save_doc) { {'ok' => true} }

        subject.recreate_user('user', 'pw')
      end
    end

    describe "#assign_roles" do
      it "should lock down database roles and create design doc for validation" do
         db = mock
        CouchRest.stub(:database) { db }
        db.should_receive(:get).with('_security') { nil }
        db.should_receive(:save_doc)
          .with({
                  '_id' => '_security',
                  'admins' => {'roles' => %w( admin )},
                  'readers' => {'roles' => %w( reader )}
                }) { {'ok' => true} }

        db.should_receive(:get).with('_design/auth') { nil }
        db.should_receive(:save_doc)
          .with({
                  '_id' => '_design/auth',
                  'language' => 'javascript',
                  'validate_doc_update' => "function(newDoc, oldDoc, userCtx) { if (userCtx.roles.indexOf('_admin') != -1) { return; } else { throw({forbidden: 'Only admins may edit the database'}); } }"
                }) { {'ok' => true} }

        subject.assign_roles
      end

    end

    describe "#host" do
      context "there is a couchdb config file present" do
        it "returns the repository host defined in the config file" do
          V1::Config.stub(:dpla) {
            { 'repository' => { 'host' => "example.com:4242" } }
          }

          expect(subject.host).to eq "example.com:4242"  
        end
      end
      context "there is no repository host defined in the config file" do
        it "returns default host values" do
          V1::Config.stub(:dpla) {
            {}
          }

          expect(subject.host).to eq "127.0.0.1:5984"
        end
      end
    end
    
    describe "set of functions depending on the DPLA config file" do
      before :each do
        V1::Config.stub(:dpla) {{
          "read_only_user" => { "username" => "u", "password" => "pw" },
          "repository" => { "admin_endpoint" => "http://admin:apass@abc.com" }
        }}
        subject.stub(:host) { "abc.com" }
      end
      
      describe "#read_only_endpoint" do
  
        it "returns the repository endpoint and the repo database in URL form" do
          stub_const("V1::Config::REPOSITORY_DATABASE", "some_db")
          expect(subject.read_only_endpoint).to eq('http://u:pw@abc.com/some_db')
        end
  
      end

      describe "#admin_endpoint" do
        context "when a repository has been defined" do
          it "returns an endpoint with admin credentials" do
            expect(subject.admin_endpoint).to eq("http://admin:apass@abc.com")
          end
        end
      end

    end

    describe "#service_status" do
      it "returns a string for a failed HTTP get by default" do
        HTTParty.should_receive(:get).and_raise Exception
        expect(subject.service_status).to match /^Error: /i
      end

      it "raises an Exception for a failed HTTP get when requested" do
        HTTParty.should_receive(:get).and_raise Exception, 'Connection Refused'
        expect {
          subject.service_status(true)
        }.to raise_error /Connection Refused/i
      end
      
    end

  end

end
