require 'v1/search_engine'

module V1

  module SearchEngine

    describe SearchEngine do
      before(:each) do
        # No need to check this inside unit tests
        subject.stub(:endpoint_config_check)
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
          subject.should_receive(:create_river)
          subject.stub(:doc_count)
          subject.stub(:puts)

          subject.recreate_env!
        end
      end

      describe "#recreate_index!" do

        it "re-creates the search index with correct name and mapping" do
          tire = double
          tire.stub_chain(:response, :code) { 200 }
          subject.stub(:sleep)
          subject.should_receive(:delete_index).with(Config.search_index)
          subject.should_receive(:create_index).with(Config.search_index)

          subject.recreate_index!
        end

      end

      describe "#import_data_file" do
        before(:each) do
          subject.stub(:display_import_result)
        end
        it "imports the correct resource type" do
          tire = double.as_null_object
          input_file = double
          Tire.should_receive(:index).with(Config.search_index).and_yield(tire)

          subject.should_receive(:process_input_file).with('foo.json', true) { input_file }
          tire.should_receive(:import).with(input_file)
          subject.import_data_file('foo.json')
          
        end
        
      end

      describe "#import_test_dataset" do
        it "imports test data for all resources" do
          subject.should_receive(:import_data_file).with(SearchEngine::ITEMS_JSON_FILE)
          subject.should_receive(:import_data_file).with(SearchEngine::COLLECTIONS_JSON_FILE)
          subject.import_test_dataset
        end
      end

      describe "#process_input_file" do
        it "injects a new _type field using the ingestType field when requested" do
          file_stub = double
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
          file_stub = double
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
            expect(subject.process_input_file('foo', double))
          }.to raise_error /JSON parse error/i
        end
      end

    end

  end

end
