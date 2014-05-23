require 'v1/repository'

module V1

  describe Repository do

    context "Module constants" do

      it "have the correct values" do
        expect(subject::DEFAULT_API_AUTH_DATABASE).to eq 'dpla_api_auth'
        expect(subject::DEFAULT_DASHBOARD_DATABASE).to eq 'dashboard'
      end

    end

    context "database/user management" do

      describe "#recreate_database" do
        it "deletes and creates a database correctly" do
          couchdb = double
          couchdb.should_receive(:delete!)
          couchdb.should_receive(:create!)

          subject.recreate_database(couchdb)
        end
      end

      describe "#recreate_env" do

        before :each do
          subject.stub(:doc_count)
          subject.stub(:puts)
          subject.should_receive(:recreate_doc_database)
          subject.should_receive(:recreate_api_keys_database)
          subject.should_receive(:recreate_users)
          subject.should_receive(:import_test_api_keys)
          subject.should_receive(:create_api_auth_views)
        end
        
        it "does not recreate_river by default" do
          SearchEngine.should_not_receive(:recreate_river)
          subject.recreate_env
        end

        it "has all the right moves and creates the river if requested" do
          SearchEngine.should_receive(:recreate_river)
          subject.recreate_env(true)
        end
      end

    end

    describe "#format_results" do
      it "reformats results properly" do
        results = [
                   {
                     "id"=>"A",
                     "key"=>"A",
                     "doc"=> {
                       "_id"=>"A",
                       "_rev"=>"1-A",
                       "id"=>"aaa",
                       "title"=>"title A"
                     }
                   },
                   {
                     "id"=>"B",
                     "key"=>"B",
                     "doc"=> {
                       "_id"=>"B",
                       "_rev"=>"1-B",
                       "id"=>"bbb",
                       "title"=>"title B"
                     }
                   }
                  ]

        expect(subject.format_results(results)).to match_array(
          [
           {"_id" => "A", "id"=>"aaa", "title"=>"title A"},
           {"_id" => "B", "id"=>"bbb", "title"=>"title B"}
          ]
        )
      end
      
      it "gracefully handles 1/1 missing fetch results" do
        results = [{"key"=>"a", "error"=>"not_found"}]
        expect {
          subject.format_results(results)
        }.not_to raise_error
      end
      
      it "gracefully handles 2/2 missing fetch results" do
        results = [
                   {"key"=>"a", "error"=>"not_found"},
                   {"key"=>"b", "error"=>"not_found"},
                  ]
        expect {
          subject.format_results(results)
        }.not_to raise_error
      end
      
      it "gracefully handles 1/2 missing fetch results" do
        results = [
                   {"key"=>"a", "error"=>"not_found"},
                   {"_id" => "B", "id"=>"b", "title"=>"foo", "_rev"=>"d9g7bc1"}
                  ]
        expect {
          subject.format_results(results)
        }.not_to raise_error
      end
      
    end

    describe "#fetch" do

      it "hits the reader endpoint" do
        subject.stub(:wrap_results)
        db_mock = double(:get_bulk => { "rows" => [double] } )
        subject.should_receive(:reader_cluster_database) { db_mock }
        subject.fetch("1")
      end

    end

    describe "#import_data_file" do
      it "calls import_docs with correct params" do
        data_file = double
        processed_input_file = double
        SearchEngine.should_receive(:process_input_file).with(data_file, false) { processed_input_file }
        subject.should_receive(:import_docs).with(processed_input_file)
        subject.import_data_file(data_file)
      end
    end

    describe "#import_test_dataset" do
      it "imports test data for all resources" do
        subject.should_receive(:import_data_file).with(SearchEngine::ITEMS_JSON_FILE)
        subject.should_receive(:import_data_file).with(SearchEngine::COLLECTIONS_JSON_FILE)
        subject.import_test_dataset
      end
    end

    describe "#import_docs" do
      it "imports the correct resource type via the admin endpoint" do
        couchdb = double
        subject.stub(:admin_cluster_database) { couchdb }

        docs = [double]
        couchdb.should_receive(:bulk_save).with(docs)

        subject.import_docs(docs)
      end

      it "raises an Exception if the bulk_save raises a BadRequest exception" do
        couchdb = double
        subject.stub(:admin_cluster_database) { couchdb }
        couchdb.stub(:bulk_save).and_raise RestClient::BadRequest

        expect {
          subject.import_docs([double])
        }.to raise_error Exception, /^Error/
      end
    end

    describe "#delete_docs" do
      it "delegates to CouchRest with correct params" do
        couchdb = double
        subject.stub(:admin_cluster_database) { couchdb }

        docs = [double, double]
        # lazy way to test that it calls delete on all elements of docs array param
        couchdb.should_receive(:delete_doc).with(docs.first)
        couchdb.should_receive(:delete_doc).with(docs.last)

        subject.delete_docs(docs)        
      end
    end

    describe "#recreate_user" do
      
      before :each do
        subject.stub(:sleep)
        Config.stub(:dpla) {{
            'repository' => {
              'reader' => {
                'user' => 'dpla-reader',
                'pass' => 'pizza',
              }
            }
          }}
        subject.stub(:node_endpoint).with('admin', '/_users') { 'node_endpoint/_users' }
        subject.stub(:database).with('node_endpoint/_users') { user_db }
      end

      let(:user_db) { double('db') }
      let(:reader) { double('ro_user') }

      it "deletes the existing read-only users" do
        user_db.stub(:get).with("org.couchdb.user:dpla-reader") { reader }
        subject.stub(:sleep)
        user_db.should_receive(:delete_doc).with(reader) { {'ok' => true} }
        user_db.stub(:save_doc) { {'ok' => true} }

        subject.recreate_user
      end

      it "gracefully handles no pre-existing user to delete" do
        user_db.stub(:get).with("org.couchdb.user:dpla-reader").and_raise RestClient::ResourceNotFound
        user_db.stub(:save_doc) { {'ok' => true} }

        expect {
          subject.recreate_user
        }.not_to raise_error
      end

      it "creates a user" do
        user_db.stub(:get).with("org.couchdb.user:dpla-reader") { reader }
        user_db.stub(:delete_doc) { {'ok' => true} }

        user_db.should_receive(:save_doc) { {'ok' => true} }
        subject.recreate_user
      end

      it "correctly encrypts the password when creating a user" do
        salt = 'ABC'
        password_sha = 'pizzaABC'
        SecureRandom.stub(:hex) { salt }
        Digest::SHA1.stub(:hexdigest).with('pizza' + salt) { password_sha }

        user_db.stub(:get).with("org.couchdb.user:dpla-reader") { reader }
        user_db.stub(:delete_doc) { {'ok' => true} }

        user_db.should_receive(:save_doc)
          .with(
                hash_including('salt' => salt, 'password_sha' => password_sha)
                )  { {'ok' => true} }

        subject.recreate_user
      end
    end

    # describe "#assign_roles" do
    #   it "should lock down database roles and create design doc for validation" do
    #     db = double
    #     CouchRest.stub(:database) { db }
    #     db.should_receive(:get).with('_security') { nil }
    #     db.should_receive(:save_doc)
    #       .with({
    #               '_id' => '_security',
    #               'admins' => {'roles' => %w( admin )},
    #               'readers' => {'roles' => %w( reader )}
    #             }) { {'ok' => true} }

    #     db.should_receive(:get).with('_design/auth') { nil }
    #     db.should_receive(:save_doc)
    #       .with({
    #               '_id' => '_design/auth',
    #               'language' => 'javascript',
    #               'validate_doc_update' => "function(newDoc, oldDoc, userCtx) { if (userCtx.roles.indexOf('_admin') != -1) { return; } else { throw({forbidden: 'Only admins may edit the database'}); } }"
    #             }) { {'ok' => true} }

    #     subject.assign_roles
    #   end

    # end

    context "config accessors" do
      #TODO: comment this before block out
      before :each do
        Config.stub(:dpla) {{
          "read_only_user" => { "username" => "u", "password" => "pw" },
          "repository" => { "admin_endpoint" => "http://admin:apass@abc.com" }
        }}
        subject.stub(:host) { "abc.com" }
      end
      
       describe "#cluster_host" do
        it "returns the cluster_host var when it is defined" do
          Config.stub(:dpla) {{
              'repository' => { 'cluster_host' => '1.2.3.4:5986' }
            }}
          expect(subject.cluster_host).to eq '1.2.3.4:5986'
        end
        it "returns the node_host var when cluster_host is not defined" do
          Config.stub(:dpla) {{
              'repository' => { 'node_host' => '1.2.3.4:5984' }
            }}
          expect(subject.cluster_host).to eq '1.2.3.4:5984'
        end
      end
      describe "#node_host" do
        it "defaults to correct host and IP when no hosts are defined" do
          Config.stub(:dpla) {{
              'repository' => {  }
            }}
          expect(subject.node_host).to eq "127.0.0.1:5984"
        end
      end
      
      describe "#build_endpoint" do
        before(:each) do
          Config.stub(:dpla) {{
              'repository' => {
                'admin' => {
                  'user' => 'dpla-admin',
                  'pass' => 'adminpass',
                },
                'reader' => {
                  'user' => 'dpla-reader',
                  'pass' => 'readerpass',
                }
              }
            }}
        end
        it "builds an endpoint" do
          expect(subject.build_endpoint('repohost:1234')).to eq 'repohost:1234'
        end
        it "builds an endpoint with a role" do
          expect(subject.build_endpoint('repohost:1234', 'admin'))
            .to eq 'dpla-admin:adminpass@repohost:1234'
        end
        it "builds an endpoint with a role and a suffix with no leading slash" do
          expect(subject.build_endpoint('repohost:1234', 'admin', 'dbname'))
            .to eq 'dpla-admin:adminpass@repohost:1234/dbname'
        end
        it "builds an endpoint with a role and a suffix with a leading slash" do
          expect(subject.build_endpoint('repohost:1234', 'admin', '/dbname'))
            .to eq 'dpla-admin:adminpass@repohost:1234/dbname'
        end
        it "builds an endpoint with a role that is not defined in the config" do
          expect(subject.build_endpoint('repohost:1234', 'undefined_role'))
            .to eq 'repohost:1234'
        end
      end

      describe "#cluster_endpoint" do
        it "delegates to build_endpoint with correct host param" do
          cluster_stub = double
          subject.stub(:cluster_host) { cluster_stub }
          endpoint = double 
          subject.should_receive(:build_endpoint).with(cluster_stub, anything, anything) { endpoint }
          subject.stub(:database).with(endpoint) { endpoint }
          expect(subject.cluster_endpoint()).to eq endpoint
        end
      end

      describe "#admin_cluster_database" do
        it "delegates correctly" do
          subject.should_receive(:cluster_endpoint).with('reader', subject.repo_name)
          subject.stub(:database)
          subject.reader_cluster_database
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
