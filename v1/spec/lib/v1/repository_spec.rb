require 'v1/repository'

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
        @db_mock = mock 'db'
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


    describe "#create_read_only_user" do
      
      before :each do
        V1::Config.stub(:dpla) {{
          'read_only_user' => {
            'username' => 'user',
            'password' => 'pw'
          },
          'repository' => {
            'admin_endpoint' => 'http://a:b@abc.com',
            'password' => 'pw'
          }
        }}
        @db_mock = mock('db')
        @read_only_user = mock("ro_user")
      end

      it "should delete any existing read-only users" do
        CouchRest.should_receive(:database).with("#{V1::Repository.admin_endpoint}/_users") { @db_mock }
        @db_mock.should_receive(:get).with("org.couchdb.user:user") { @read_only_user }
        @read_only_user.should_receive(:is_a?) { true }
        @db_mock.should_receive(:delete_doc) { 200 }
        RestClient.should_receive(:put) { 200 }
        V1::Repository.create_read_only_user
      end

      it "creates a user" do
        CouchRest.should_receive(:database).with("#{V1::Repository.admin_endpoint}/_users") { @db_mock }
        @db_mock.should_receive(:get).with("org.couchdb.user:user") { @read_only_user }
        @read_only_user.should_receive(:is_a?) { false }
        RestClient.should_receive(:put) { 200 }
        V1::Repository.create_read_only_user
      end
    end

    describe "#lock_down_repository_roles" do

      it "should lock down database roles and create design doc for validation" do
        RestClient.should_receive(:put).with(
          "#{V1::Repository.admin_endpoint}/#{V1::Repository.repository_database}/_security",
          anything()
        )
        RestClient.should_receive(:put).with(
          "#{V1::Repository.admin_endpoint}/#{V1::Repository.repository_database}/_design/auth",
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
    
    describe "#host" do
      context "there is a couchdb config file present" do
        it "returns the repository host defined in the config file" do
          config_values = {
              'repository' => { 'host' => "example.com:4242" }
          }

          YAML.stub(:load_file) { config_values }
          expect(subject.host).to eq "example.com:4242"  
        end
      end
      context "there is no couchdb config file present" do
        it "returns default host values" do
          config_values = {}

          YAML.stub(:load_file) { config_values }
          expect(subject.host).to eq "127.0.0.1:5984"
        end
      end
    end
    
    describe "set of functions depending on the DPLA config file" do
      before :each do
        V1::Config.stub(:dpla) {{
          "read_only_user" => { "username" => "u", "password" => "pw" },
          "repository" => { 
            "admin_endpoint" => "http://admin:apass@abc.com"
          }
        }}
        subject.stub(:host) { "abc.com" }
      end
      
      describe "#read_only_endpoint" do
  
        it "returns the repository endpoint and the repo database in URL form" do
          stub_const("V1::Config::REPOSITORY_DATABASE", "some_db")
          expect(V1::Repository.read_only_endpoint).to eq('http://u:pw@abc.com/some_db')
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

  end

end
