require 'v1/schema'

module V1

  describe Schema do

    context "Module constants" do

      describe "V1::Schema::ELASTICSEARCH_MAPPING" do
        it "is frozen" do
          expect(V1::Schema::ELASTICSEARCH_MAPPING.frozen?).to be_true
        end
        it "has the expected top level structure" do
          expect(V1::Schema::ELASTICSEARCH_MAPPING).to be_a Hash
          expect(V1::Schema::ELASTICSEARCH_MAPPING).to have_key 'mappings'
          expect(V1::Schema::ELASTICSEARCH_MAPPING['mappings']).to have_key 'item'
          expect(V1::Schema::ELASTICSEARCH_MAPPING['mappings']['item']).to have_key 'properties'
        end
      end

    end

    context "mapping methods" do
      let(:full_mapping) {
        {
          'mappings' => {
            'item' => {
              'properties' => {
                'title' => { :type => 'string' },
                'created' => { :type => 'date' },
                'temporal' => {
                  'properties' => {
                    'start' => { :type => 'date' },
                    'end' => { :type => 'date' }
                  }
                },
                'spatial' => {
                  'properties' => {
                    'city' => { :type => 'string', :index => 'not_analyzed' },
                    'coordinates' => { :type => "geo_point" }
                  }
                },
                'someBlob' => { 'enabled' => false },
              }
            },
            'collection' => {
              'properties' => {
                'title' => { :type => 'string' }
              }
            }
          }
        }
      }
      
      before(:each) do
        stub_const("V1::Schema::ELASTICSEARCH_MAPPING", full_mapping)
      end

      describe "#mapping" do
        it "defaults to returning entire item mapping" do
          expect(subject.mapping()).to eq full_mapping['mappings']
        end

        it "returns entire mapping for a single type" do
          expect(
                 subject.mapping('item')
                 ).to eq(full_mapping['mappings']['item']['properties'])
        end

        it "returns the mapping for a single field as requested" do
          expect(subject.mapping('item', 'created')).to eq( {:type => 'date' } )
          expect(subject.mapping('collection', 'title')).to eq( {:type => 'string'} )
        end

        it "maps dotted names to nested hashes" do
          expect(
                 subject.mapping('item', 'spatial.city')
                 ).to eq( {:type => "string", :index => "not_analyzed"} )
        end

        it "returns nil for non-existent types" do
          expect(subject.mapping('really_fake_type')).to eq nil
        end

        it "returns nil for non-existent fields" do
          expect(subject.mapping('item', :non_existent_field_lol)).to eq nil
        end
      end

      describe "#item_mapping" do
        it "retrieves 'item' mapping by default" do
          expect(subject.item_mapping).to eq subject.mapping('item')
        end
        it "delegates to mapping() with correct params" do
          foo_mapping = stub
          subject.should_receive(:mapping).with('item', :foo) { foo_mapping }
          expect(subject.item_mapping(:foo)).to eq foo_mapping
        end
      end

      describe "#mapped_fields" do
        let(:mapped_fields) { V1::Schema.mapped_fields }

        it "includes an expected basic string field" do
          expect(mapped_fields).to include 'title'
        end
        it "includes $field.before and $field.after for top-level date field" do
          expect(mapped_fields).to include 'created.before'
          expect(mapped_fields).to include 'created.after'
        end
        it "handles the TODO: special case of temporal.before and temporal.after" do
          expect(mapped_fields).to include 'temporal.before'
          expect(mapped_fields).to include 'temporal.after'
        end
        it "includes $field.distance for a geo_point field" do
          expect(mapped_fields).to include 'spatial.distance'
        end
        it "excludes $field where 'enabled' is false" do
          expect(mapped_fields).not_to include 'someBlob'
        end
      end

    end

  end

end
