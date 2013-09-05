require 'v1/search_engine/river'

module V1

  module SearchEngine

    module River

      describe River do

        describe "#endpoint" do
          it "returns correct value" do
            Config.stub(:search_endpoint) { 'server:9200' }
            subject.stub(:river_name) { 'danube' }
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

      end

    end

  end

end

