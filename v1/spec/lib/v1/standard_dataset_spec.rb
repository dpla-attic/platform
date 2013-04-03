require 'v1/standard_dataset'

module V1

  module StandardDataset

    describe StandardDataset do
      before(:each) do
        # No need to check this inside unit tests
        subject.stub(:endpoint_config_check)
      end

      context "Constants" do
        describe "SEARCH_RIVER_NAME" do
          it "is correct" do
            expect(SEARCH_RIVER_NAME).to eq 'dpla_river'
          end
        end
      end

      describe "#dataset_files" do
        it "should list all the dataset files" do
          expect(subject.dataset_files)
            .to match_array (
                             [
                              ITEMS_JSON_FILE,
                              COLLECTIONS_JSON_FILE
                             ])
        end
      end
      
      describe "#recreate_env!" do
        it "calls the correct methods in the correct order" do
          subject.should_receive(:recreate_index!)
          subject.should_receive(:import_test_dataset)
          subject.stub(:doc_count)
          subject.stub(:puts)
          subject.recreate_env!
        end
      end

      describe "#recreate_index!" do

        it "re-creates the search index with correct name and mapping" do
          tire = mock
          tire.stub_chain(:response, :code) { 200 }
          subject.stub(:sleep)
          subject.should_receive(:delete_river)
          Tire.should_receive(:index).with(V1::Config::SEARCH_INDEX).and_yield(tire)
          tire.should_receive(:delete)
          tire.should_receive(:create).with( { 'mappings' => V1::Schema::ELASTICSEARCH_MAPPING } )
          subject.should_receive(:create_river)
          
          subject.recreate_index!
        end

      end

      describe "#import_data_file" do
        before(:each) do
          subject.stub(:display_import_result)
        end
        it "imports the correct resource type" do
          tire = mock.as_null_object
          input_file = stub
          Tire.should_receive(:index).with(V1::Config::SEARCH_INDEX).and_yield(tire)

          subject.should_receive(:process_input_file).with('foo.json', true) { input_file }
          tire.should_receive(:import).with(input_file)
          subject.import_data_file('foo.json')
          
        end
        
      end

      describe "#import_test_dataset" do
        it "imports test data for all resources" do
          subject.should_receive(:import_data_file).with(V1::StandardDataset::ITEMS_JSON_FILE)
          subject.should_receive(:import_data_file).with(V1::StandardDataset::COLLECTIONS_JSON_FILE)
          subject.import_test_dataset
        end
      end

      describe "#process_input_file" do
        it "injects a new _type field using the ingestType field when requested" do
          file_stub = stub
          File.should_receive(:read).with(file_stub)
          json_contents = [ {'id' => 1, 'ingestType' => 'sometype'}, {'id' => 2, 'ingestType' => 'sometype'} ]
          JSON.stub(:load) { json_contents }

          expect(subject.process_input_file(file_stub, true))
            .to match_array([
                             {'id' => 1, '_type' => 'sometype', 'ingestType' => 'sometype'},
                             {'id' => 2, '_type' => 'sometype', 'ingestType' => 'sometype'}
                            ])
        end
        
        it "does not inject a new _type field when it's not requested" do
          file_stub = stub
          File.should_receive(:read).with(file_stub)
          json_contents = [ {'id' => 1, 'ingestType' => 'sometype'}, {'id' => 2, 'ingestType' => 'sometype'} ]
          JSON.stub(:load) { json_contents }

          expect(subject.process_input_file(file_stub, false))
            .to match_array([
                             {'id' => 1, 'ingestType' => 'sometype'},
                             {'id' => 2, 'ingestType' => 'sometype'}
                            ])
        end
        it "raises an error when there is invalid JSON in a test data file" do
          File.stub(:read) { "invalid json here\nAnd on the second line" }
          expect {
            expect(subject.process_input_file('foo', stub))
          }.to raise_error /JSON parse error/i
        end
      end

      describe "#river_endpoint" do
        it "returns correct value" do
          V1::Config.stub(:search_endpoint) { 'server:9200' }
          stub_const("V1::StandardDataset::SEARCH_RIVER_NAME", 'danube')
          expect(subject.river_endpoint).to eq 'server:9200/_river/danube'
        end
      end

    end

  end

end
