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
        it "has the correct number of items" do
          expect(
                 V1::Schema::ELASTICSEARCH_MAPPING['mappings']['item']['properties']
                 ).to have(20).items
        end
      end

    end

    context "mapping methods" do
      let(:mock_mapping) {
        {
          'mappings' => {
            'item' => {
              'properties' => {
                'id' => { 'type' => 'string', 'facet' => true },
                'title' => { 'type' => 'string' },
                'description' => { 'type' => 'string' },
                'created' => { 'type' => 'date', 'facet' => true },
                'temporal' => {
                  'properties' => {
                    'start' => { 'type' => 'date', 'facet' => true },
                    'end' => { 'type' => 'date', 'facet' => true }
                  }
                },
                'spatial' => {
                  'properties' => {
                    'city' => { 'type' => 'string', 'index' => "not_analyzed" },
                    'iso3166-2' => { 'type' => 'string', :index => 'not_analyzed', 'facet' => true },
                    'coordinates' => { 'type' => "geo_point" }
                  }
                },
                'isPartOf' => {
                  'properties' => {
                    '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'facet' => true },
                    'name' => {
                      'type' => 'multi_field',
                      'fields' => {
                        'name' => {'type' => 'string' },
                        'raw' => {'type' => 'string', 'index' => 'not_analyzed', 'facet' => true }
                      }
                    }
                  }
                },
                'field1' => {
                  'properties' => {
                    'name' => {
                      'type' => 'multi_field',
                      'fields' => {
                        'name' => {'type' => 'string', 'index' => 'analyzed' }
                      }
                    }
                  }
                },
                'field2' => {
                  'properties' => {
                    'sub2a' => {'type' => 'string', 'index' => 'not_analyzed', 'facet' => true },
                    'sub2b' => {'type' => 'string', 'index' => 'not_analyzed'}
                  }
                },
                'field3' => {
                  'properties' => {
                    'sub3a' => {'type' => 'string' },
                    'sub3b' => {'type' => 'string' }
                  }
                },
                'someBlob' => { 'enabled' => false },
              }
            },
            'collection' => {
              'properties' => {
                'title' => { 'type' => 'string' }
              }
            }
          }
        }
      }
      
      before(:each) do
        stub_const("V1::Schema::ELASTICSEARCH_MAPPING", mock_mapping)
      end

      describe "#mapping" do
        it "defaults to returning entire item mapping" do
          expect(subject.mapping()).to eq mock_mapping['mappings']
        end

        it "returns entire mapping for a single type" do
          expect(
                 subject.mapping('item')
                 ).to eq(mock_mapping['mappings']['item']['properties'])
        end

        it "returns the mapping for a single field as requested" do
          expect(subject.mapping('item', 'created')).to eq( {'type' => 'date', 'facet' => true } )
          expect(subject.mapping('collection', 'title')).to eq( {'type' => 'string'} )
        end

        it "maps dotted names to nested hashes" do
          expect(subject.mapping('item', 'spatial.city'))
            .to eq( {'type' => "string", 'index' => "not_analyzed"} )
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

      describe "#queryable_fields" do
        let(:queryable_fields) { V1::Schema.queryable_fields }

        it "includes an expected basic string field" do
          expect(queryable_fields).to include 'title'
        end
        it "includes $field.before and $field.after for top-level date field" do
          expect(queryable_fields).to include 'created.before'
          expect(queryable_fields).to include 'created.after'
        end
        it "handles the special case of temporal.before and temporal.after" do
          expect(queryable_fields).to include 'temporal.before'
          expect(queryable_fields).to include 'temporal.after'
        end
        it "includes $field.distance for a geo_point field" do
          expect(queryable_fields).to include 'spatial.distance'
        end
        it "excludes $field where 'enabled' is false" do
          expect(queryable_fields).not_to include 'someBlob'
        end
      end

      describe "#flapping" do
        let(:item_mapping) { mock_mapping['mappings']['item']['properties'] }

        it "creates a top level field correctly" do
          fieldstub = stub
          name = 'title'
          V1::Schema::Field.should_receive(:new)
            .with('item',
                  name,
                  item_mapping[name],
                  nil
                  ) { fieldstub }
          expect(V1::Schema.flapping('item', name)).to eq fieldstub
        end

        it "creates a subfield field correctly" do
          subfieldstub = stub
          name = 'temporal.start'
          V1::Schema::Field.should_receive(:new)
            .with(
                  'item',
                  name,
                  item_mapping['temporal']['properties']['start'],
                  nil
                  ) { subfieldstub }
          expect(V1::Schema.flapping('item', name)).to eq subfieldstub
        end

        it "calls Field.new with correct params" do
          fieldstub = stub
          name = 'title'
          V1::Schema::Field.should_receive(:new)
            .with('item',
                  name,
                  item_mapping[name],
                  '.some_extra'
                  ) { fieldstub }
          expect(V1::Schema.flapping('item', name, '.some_extra')).to eq fieldstub
        end

        it "returns nil for an unrecognized mapping" do
          name = 'some_invalid_field'
          V1::Schema::Field.should_not_receive(:new)
          expect(V1::Schema.flapping('item', name)).to eq nil
        end 

      end      

    end

  end

end
