require 'v1/search_engine/river'
require 'spec_helper'

module V1

  module SearchEngine

    module River

      describe River do

        before(:each) do
            Config.stub(:search_endpoint) { 'server:9200' }
            subject.stub(:river_name) { 'danube' }          
        end

        describe "#endpoint" do
          it "returns correct value" do
            expect(subject.endpoint).to eq 'server:9200/_river/danube'
          end
        end

        describe "#river_creation_doc" do
          it "returns the correct content" do
            database_uri = 'http://user1:pass1@host:5984/db1'
            expect(subject.river_creation_doc('index1', database_uri))
              .to eq(
                     {
                       'type' => 'couchdb',
                       'couchdb' => {
                         'host' => 'host',
                         'port' => 5984,
                         'db' => 'db1',
                         'user' => 'user1',
                         'password' => 'pass1',
                         'bulk_size' => '500',
                         'bulk_timeout' => '3s',
                         'script' => subject.river_script
                       },
                       'index' => {
                         'index' => 'index1'
                       }
                     }
                     )
          end
        end

        context "with HTTP transactions" do
          let(:resp) { double }
          let(:error_body) { '{"error": "fooey"}' }

          describe ".last_sequence" do
            before do
                allow(HTTParty).to receive(:get)
                  .with('server:9200/_river/danube/_seq')
                  .and_return(resp)
            end

            context "with successful HTTP response" do
              let(:parsed_resp) {
                {
                  '_source' => {
                    'couchdb' => {
                      'last_seq' => "1"
                    }                  
                  }
                }
              }
              before do
                allow(resp).to receive(:parsed_response)
                  .and_return(parsed_resp)
                allow(resp).to receive(:success?).and_return(true)
              end

              it "returns the correct last_seq from response" do
                expect(subject.last_sequence).to eq("1")
              end
            end

            context "with unsuccessful HTTP response" do
              before do
                allow(resp).to receive(:success?).and_return(false)
                allow(resp).to receive(:body).and_return(error_body)
              end

              it "raises an exception" do
                expect {subject.last_sequence}
                  .to raise_error(RuntimeError,
                                  /^Problem getting last sequence/)
              end
            end
          end

          describe ".last_sequence!" do
            let(:putdata) {
              {couchdb: {last_seq: "1"}}
            }
            before do
            end

            context "with successful HTTP response" do
              before do
                allow(resp).to receive(:success?).and_return(true)
              end

              it "makes a PUT request with the right properties" do
                ["1", "2"].each do |n|
                  putdata[:couchdb][:last_seq] = n
                  expect(HTTParty).to receive(:put)
                    .with('server:9200/_river/danube/_seq',
                          {body: putdata.to_json})
                    .and_return(resp)
                  subject.last_sequence!(n)
                end
              end
            end

            context "with unsuccessful HTTP response" do
              before do
                allow(resp).to receive(:success?).and_return(false)
                allow(resp).to receive(:body).and_return(error_body)
                allow(HTTParty).to receive(:put).and_return(resp)
              end

              it "raises an exception" do
                expect {subject.last_sequence!(0)}
                  .to raise_error(RuntimeError,
                                  /^Problem setting river sequence/)
              end
            end
          end  # .last_sequence!

          describe ".last_sequence_number" do
            it "returns the correct integer when the sequence is a " \
               "JSON-encoded array from CouchDB's _changes endpoint" do
              allow(subject)
                .to receive(:last_sequence)
                .and_return("[3253021,\"g1AAAAFzeJzLYWBg4MhgTmEQSspM...\"]")
              expect(subject.last_sequence_number).to eq(3253021)
            end

            it "returns correct integer when sequence is numeric string" do
              allow(subject)
                .to receive(:last_sequence)
                .and_return("123")
              expect(subject.last_sequence_number).to eq(123)
            end

            it "returns correct integer when sequence is an integer" do
              allow(subject)
                .to receive(:last_sequence)
                .and_return(123)
              expect(subject.last_sequence_number).to eq(123)
            end

          end

          describe ".create_river" do
            let(:opts) {
              {
                'river' => 'the_river',
                'index' => 'the_index',
                'last_seq' => '0'
              }
            }

            it "raises an exception if last sequence number is not given" do
              opts.delete('last_seq')
              expect {subject.create_river(opts)}
                .to raise_error(RuntimeError,
                                /^Last sequence number not specified/)
            end

            it "raises an exception if index does not exist" do
              opts.delete('index')
              allow(V1::SearchEngine)
                .to receive(:alias_to_index).and_return(nil)
              allow(V1::SearchEngine).to receive(:find_alias).and_return(false)
              allow(HTTParty).to receive(:put).and_return(resp)
              expect {subject.create_river(opts)}
                .to raise_error(RuntimeError,
                                /^Cannot create river/)
            end

            it "sets the last sequence for the river it will create" do
              allow(V1::SearchEngine)
                .to receive(:alias_to_index).and_return('dpla-123')
              allow(V1::SearchEngine).to receive(:find_alias).and_return(false)
              allow(HTTParty).to receive(:put).and_return(resp)
              allow(resp).to receive(:success?).and_return(true)
              allow(subject).to receive(:verify_river_status).and_return('')
              expect(subject).to receive(:last_sequence!)
                .with("0", "danube").and_return(true)
              subject.create_river(opts)
            end
          end

          describe ".recreate_river" do
            before do
              allow(subject).to receive(:last_sequence).and_return(1)
              allow(subject).to receive(:delete_river).and_return(nil)
              allow(subject).to receive(:create_river).and_return(nil)
            end

            it "looks up the river's last sequence if it's not given" do
              expect(subject).to receive(:last_sequence).and_return(1)
              subject.recreate_river  # no sequence arg
            end

            it "uses the last sequence argument if it's given" do
              expect(subject)
                .to receive(:create_river).with({'last_seq' => "2"})
              subject.recreate_river("2")
            end

            it "reports last sequence number of old river to stdout" do
              printed = capture_stdout do
                subject.recreate_river
              end
              expect(printed).to match(/Using last sequence 1/)
            end

            it "deletes the default river" do
              expect(subject).to receive(:delete_river).with().and_return(nil)
              subject.recreate_river
            end

            it "creates a new river with the old one's last sequence and " \
               "other options at their defaults" do
              last = subject.last_sequence
              expect(subject)
                .to receive(:create_river).with({'last_seq' => last})
                .and_return(nil)
              subject.recreate_river
            end
          end
        end  # with HTTP responses

      end
    end
  end
end
