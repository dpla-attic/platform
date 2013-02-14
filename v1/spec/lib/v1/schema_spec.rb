require 'v1/schema'
require 'v1/field'

module V1

  describe Schema do

    context "Module constants" do

      describe "V1::Schema::ELASTICSEARCH_MAPPING" do
        it "is frozen" do
          expect(V1::Schema::ELASTICSEARCH_MAPPING.frozen?).to be_true
        end
        it "has the expected top level structure" do
          expect(V1::Schema::ELASTICSEARCH_MAPPING).to be_a Hash
          expect(V1::Schema::ELASTICSEARCH_MAPPING).to have_key 'item'
          expect(V1::Schema::ELASTICSEARCH_MAPPING['item']['date_detection']).to be_false
          expect(V1::Schema::ELASTICSEARCH_MAPPING['item']).to have_key 'properties'
        end
        it "has the correct number of fields for 'item'" do
          expect(
                 V1::Schema::ELASTICSEARCH_MAPPING['item']['properties']
                 ).to have(12).items
        end
        it "has the correct number of fields for 'item'" do
          expect(
                 V1::Schema::ELASTICSEARCH_MAPPING['item']['properties']['aggregatedCHO']['properties']
                 ).to have(16).items
        end
      end

    end

    context "mapping methods" do
      let(:mock_mapping) {
        {
          'item' => {
            'properties' => {
              'id' => { 'type' => 'string', 'facet' => true },
              'aggregatedCHO' => {
                'properties' => {
                  'title' => { 'type' => 'string' },
                  'description' => { 'type' => 'string' },
                  'date' => {
                    'properties' => {
                      'displayDate' => { 'type' => 'string', 'index' => 'not_analyzed'},
                      'begin' => { 'type' => 'date', 'facet' => true },
                      'end' => { 'type' => 'date', 'facet' => true }
                    }
                  },
                  'level1' => {
                    'properties' => {
                      'level2' => {
                        'properties' => {
                          'level3A' => { 'type' => 'string'},
                          'level3B' => { 'type' => 'string'}
                        }
                      }
                    }
                  },
                  'temporal' => {
                    'properties' => {
                      'begin' => { 'type' => 'date', 'facet' => true },
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
                }
              },  #/aggregatedCHO
              'dataProvider' => { 'type' => 'string' },
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

      before(:each) do
        stub_const("V1::Schema::ELASTICSEARCH_MAPPING", mock_mapping)
      end

      describe "#queryable_fields" do
        let(:queryable_fields) { V1::Schema.queryable_fields }

        it "includes an expected basic string field" do
          expect(queryable_fields).to include 'aggregatedCHO.title'
        end
        it "includes $field.before and $field.after for top-level date fields" do
          expect(queryable_fields).to include 'aggregatedCHO.date.before'
          expect(queryable_fields).to include 'aggregatedCHO.date.after'
          expect(queryable_fields).to include 'aggregatedCHO.temporal.before'
          expect(queryable_fields).to include 'aggregatedCHO.temporal.after'
        end
        it "includes $field.distance for a geo_point field" do
          expect(queryable_fields).to include 'aggregatedCHO.spatial.distance'
        end
        it "excludes $field where 'enabled' is false" do
          expect(queryable_fields).not_to include 'someBlob'
        end
      end
      describe "#field" do
        let(:item_mapping) { mock_mapping['item']['properties'] }

        #TODO: move to field_spec once its schema is updated
        describe "#subdeep" do
          it "is right" do
            f = V1::Field.new(
                              'item',
                              'aggregatedCHO.level1',
                              item_mapping['aggregatedCHO']['properties']['level1']
                              )

            expect(f.subfields_deep.map(&:name))
              .to match_array(
                              %w( aggregatedCHO.level1 aggregatedCHO.level1.level2 aggregatedCHO.level1.level2.level3A aggregatedCHO.level1.level2.level3B )
                              )
          end
        end

        it "raises an exception for an invalid resource" do
          expect {
            V1::Schema.field('fake_resource', 'some_field')
          }.to raise_error /invalid resource: fake_resource/i
        end

        it "creates a top level field with no subfields correctly" do
          fieldstub = stub
          name = 'dataProvider'
          V1::Field.should_receive(:new)
            .with('item',
                  name,
                  item_mapping[name],
                  nil
                  ) { fieldstub }
          expect(V1::Schema.field('item', name)).to eq fieldstub
        end

        it "creates a top level field with subfields correctly" do
          fieldstub = stub
          name = 'aggregatedCHO.temporal'
          V1::Field.should_receive(:new)
            .with('item',
                  name,
                  item_mapping['aggregatedCHO']['properties']['temporal'],
                  nil
                  ) { fieldstub }
          expect(V1::Schema.field('item', name)).to eq fieldstub
        end

        it "creates a subfield field correctly" do
          subfieldstub = stub
          name = 'aggregatedCHO.temporal.begin'
          V1::Field.should_receive(:new)
            .with(
                  'item',
                  name,
                  item_mapping['aggregatedCHO']['properties']['temporal']['properties']['begin'],
                  nil
                  ) { subfieldstub }
          expect(V1::Schema.field('item', name)).to eq subfieldstub
        end

        it "passes modifier to Field.new" do
          fieldstub = stub
          name = 'dataProvider'
          V1::Field.should_receive(:new)
            .with('item',
                  name,
                  item_mapping[name],
                  '.some_extra'
                  ) { fieldstub }
          expect(V1::Schema.field('item', name, '.some_extra')).to eq fieldstub
        end

        it "handles mid-level field with subfields" do
          midfield = stub
          name = 'aggregatedCHO.level1.level2'
          V1::Field.should_receive(:new)
            .with(
                  'item',
                  name,
                  item_mapping['aggregatedCHO']['properties']['level1']['properties']['level2'],
                  nil
                  ) { midfield }
          expect(V1::Schema.field('item', name)).to eq midfield
        end

        it "handles deeply nested field" do
          subfieldstub = stub
          name = 'aggregatedCHO.level1.level2.level3A'
          V1::Field.should_receive(:new)
            .with(
                  'item',
                  name,
                  item_mapping['aggregatedCHO']['properties']['level1']['properties']['level2']['properties']['level3A'],
                  nil
                  ) { subfieldstub }
          expect(V1::Schema.field('item', name)).to eq subfieldstub
        end

        it "returns nil for an invalid top level mapping" do
          name = 'some_invalid_field'
          V1::Field.should_not_receive(:new)
          expect(V1::Schema.field('item', name)).to eq nil
        end 

        it "returns nil for an invalid subfield of an invalid top level mapping" do
          name = 'some_invalid_field.fake_subfield'
          V1::Field.should_not_receive(:new)
          expect(V1::Schema.field('item', name)).to eq nil
        end 

        it "returns nil for an invalid subfield of a valid top level mapping" do
          name = 'level1.invalid_subfield'
          V1::Field.should_not_receive(:new)
          expect(V1::Schema.field('item', name)).to eq nil
        end 

        it "returns nil for an invalid deeply nested subfield of a valid top level mapping" do
          name = 'level1.invalid_subfield.another_invalid_field'
          V1::Field.should_not_receive(:new)
          expect(V1::Schema.field('item', name)).to eq nil
        end 

      end      

    end

  end

end
