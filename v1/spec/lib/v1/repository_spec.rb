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

      it "delegates to CouchRest get() method on correct endpoint" do
        endpoint_stub = stub 'endpoint'
        db_mock = mock('db')
        couch_doc = stub 'couch_doc'
        V1::Repository.stub(:endpoint) { endpoint_stub }
        CouchRest.should_receive(:database).with(endpoint_stub) { db_mock }
        db_mock.should_receive(:get).with("2") { couch_doc }
        expect(subject.fetch(2)).to eq couch_doc
      end

    end

    describe "#endpoint" do

      it "returns the repository endpoint and the repo database in URL form" do
        stub_const("V1::Config::REPOSITORY_DATABASE", "some_db")
        V1::Config.should_receive(:get_repository_endpoint) { 'http://foo.api:9200'} 
        expect(V1::Repository.endpoint).to eq('http://foo.api:9200' + '/' + "some_db")
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
