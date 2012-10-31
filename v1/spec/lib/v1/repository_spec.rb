require 'v1/repository'
require 'rest_client'
module V1

  describe Repository do

    describe "#recreate_database!" do
      it "uses correct repository URI to delete"
      it "uses correct repository URI to create"
      it "recreates the river after recreating the database"
      it "bulk saves the items dataset"
    end

    describe "#fetch" do
      before(:each) do
        @endpoint_stub = stub 'endpoint'
        @db_mock = mock('db')
        @couch_doc = stub 'couch_doc'
        V1::Repository.stub(:read_only_endpoint) { @endpoint_stub }
      end

      it "invokes CouchRest database on valid endpoint" do
        CouchRest.should_receive(:database).with(@endpoint_stub) { @db_mock }
        @db_mock.stub(:get_bulk) { { "rows" => [@couch_doc] } }
        subject.fetch("1")
      end

      it "delegates to CouchRest get_bulk() on comma separated string parameters" do
        CouchRest.should_receive(:database).with(@endpoint_stub) { @db_mock }
        @couch_doc_a = stub "couch_doc_z"
        @db_mock.should_receive(:get_bulk).with(["2", "Z"]) { { "rows" => [@couch_doc, @couch_doc_z] } }
        expect(subject.fetch("2,Z")).to eq [@couch_doc, @couch_doc_z]
      end

      it "delegates to CouchRest get_bulk() on single string parameter" do
        CouchRest.should_receive(:database).with(@endpoint_stub) { @db_mock }
        @db_mock.should_receive(:get_bulk).with(["2"]) { { "rows" => [@couch_doc] } }
        expect(subject.fetch("2")).to eq [@couch_doc]
      end

      it "delegates to CouchRest get_bulk() method on array of strings parameter" do
        CouchRest.should_receive(:database).with(@endpoint_stub) { @db_mock }
        @couch_doc_a = stub "couch_doc_a"
        @db_mock.should_receive(:get_bulk).with(["2", "a"]) { { "rows" => [@couch_doc, @couch_doc_a] } }
        expect(subject.fetch(["2", "a"])).to eq [@couch_doc, @couch_doc_a]
      end

    end

    describe "#read_only_endpoint" do

      it "returns the repository endpoint and the repo database in URL form" do
        stub_const("V1::Config::REPOSITORY_DATABASE", "some_db")
        V1::Config.should_receive(:get_repository_read_only_endpoint) { 'http://user:pw@foo.api:9200' }
        expect(V1::Repository.read_only_endpoint).to eq('http://user:pw@foo.api:9200' + '/' + "some_db")
      end

    end

    describe "#create_read_only_user" do
      
      before :each do
        V1::Config.stub(:get_repository_read_only_username) { "user" }
        V1::Config.stub(:get_repository_read_only_password) { "password" }
        @db_mock = mock('db')
        @read_only_user = mock("ro_user")
        V1::Repository.stub(:repository_admin_endpoint) { "http://www.example.com/repository" }
      end

      it "should delete any existing read-only users" do
        CouchRest.should_receive(:database).with("#{V1::Repository.repository_admin_endpoint}/_users") { @db_mock }
        @db_mock.should_receive(:get).with("org.couchdb.user:user") { @read_only_user }
        @read_only_user.should_receive(:is_a?) { true }
        @db_mock.should_receive(:delete_doc) { 200 }
        RestClient.should_receive(:put) { 200 }
        V1::Repository.create_read_only_user
      end

      it "creates a user" do
        CouchRest.should_receive(:database).with("#{V1::Repository.repository_admin_endpoint}/_users") { @db_mock }
        @db_mock.should_receive(:get).with("org.couchdb.user:user") { @read_only_user }
        @read_only_user.should_receive(:is_a?) { false }
        RestClient.should_receive(:put) { 200 }
        V1::Repository.create_read_only_user
      end
    end

    describe "#lock_down_repository_roles" do

      it "should lock down database roles and create design doc for validation" do
        RestClient.should_receive(:put).with(
          "#{V1::Repository.repository_admin_endpoint}/#{V1::Repository.repository_database}/_security",
          anything()
        )
        RestClient.should_receive(:put).with(
          "#{V1::Repository.repository_admin_endpoint}/#{V1::Repository.repository_database}/_design/auth",
          anything()
        )
        V1::Repository.lock_down_repository_roles
      end

    end

    describe "#process_input_file" do

      it "loads its json file param into a JSON object" do
        filename = "file.json"
        json_file = stub
        json_text = stub 'json text'
        json_object = stub 'json object'
        File.should_receive(:expand_path).with(filename, anything) { json_file }
        File.should_receive(:read).with(json_file) { json_text }
        JSON.should_receive(:load).with( json_text ) { json_object}
        expect(V1::Repository.process_input_file(filename)).to eq json_object
      end

    end

  end

end
