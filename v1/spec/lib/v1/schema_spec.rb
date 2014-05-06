require 'v1/schema'

module V1

  module Schema 

    describe Schema do
      let(:resource) { 'test_resource' }

      context "Module constants" do

        describe "ELASTICSEARCH_MAPPING" do
          it "has the expected top level structure" do
            expect(subject.full_mapping).to have_key 'item'
            expect(subject.full_mapping).to have_key 'collection'
          end
          
          context "item resource" do
            let(:resource) { 'item' }
            it "has the expected top level structure" do
              expect(subject.full_mapping[resource]['date_detection']).to be_false
              expect(subject.full_mapping[resource]).to have_key 'properties'
            end
            it "has the correct number of fields for resource" do
              expect(
                     subject.full_mapping[resource]['properties']
                     ).to have(15).items
            end
            it "has the correct number of fields for 'item/sourceResource'" do
              expect(
                     subject.full_mapping[resource]['properties']['sourceResource']['properties']
                     ).to have(20).items
            end
          end

          context "collection resource" do
            let(:resource) { 'collection' }
            it "has the expected top level structure" do
              expect(subject.full_mapping[resource]['date_detection']).to be_false
              expect(subject.full_mapping[resource]).to have_key 'properties'
            end
            it "has the correct number of fields for resource" do
              expect(
                     subject.full_mapping[resource]['properties']
                     ).to have(8).items
            end
          end
        end

      end

      context "mapping methods" do
        let(:mock_mapping) {
          {
            'test_resource' => {
              'properties' => {
                'id' => { 'type' => 'string', 'facet' => true },
                'sourceResource' => {
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
                },  #/sourceResource
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
          Schema.stub(:full_mapping) { mock_mapping }
        end

        describe "#all_fields" do

          let(:all_field_names) { subject.all_fields(resource).map(&:name) }

          it "returns the expected list of fields" do
            expect(all_field_names)
              .to match_array(%w(
                              id
                              sourceResource
                              sourceResource.title
                              sourceResource.description
                              sourceResource.date
                              sourceResource.date.displayDate
                              sourceResource.date.begin
                              sourceResource.date.end
                              sourceResource.level1
                              sourceResource.level1.level2
                              sourceResource.level1.level2.level3A
                              sourceResource.level1.level2.level3B
                              sourceResource.temporal
                              sourceResource.temporal.begin
                              sourceResource.temporal.end
                              sourceResource.spatial
                              sourceResource.spatial.city
                              sourceResource.spatial.iso3166-2
                              sourceResource.spatial.coordinates
                              sourceResource.isPartOf
                              sourceResource.isPartOf.@id
                              sourceResource.isPartOf.name
                              sourceResource.field1
                              sourceResource.field1.name
                              sourceResource.field2
                              sourceResource.field2.sub2a
                              sourceResource.field2.sub2b
                              sourceResource.field3
                              sourceResource.field3.sub3a
                              sourceResource.field3.sub3b
                              dataProvider
                              ))
          end

          # Test some specific cases
          it "includes an expected basic string field" do
            expect(all_field_names).to include 'sourceResource.title'
          end
          it "excludes $field where 'enabled' is false" do
            expect(all_field_names).not_to include 'someBlob'
          end
          it "does not contain any duplicate fields" do
            expect(all_field_names).to match_array all_field_names.uniq
          end
        end

        describe "#queryable_field_names" do
          let(:queryable_field_names) { subject.queryable_field_names(resource) }

          it "includes $field.before and $field.after for top-level date fields" do
            expect(queryable_field_names).to include 'sourceResource.date.before'
            expect(queryable_field_names).to include 'sourceResource.date.after'
            expect(queryable_field_names).to include 'sourceResource.temporal.before'
            expect(queryable_field_names).to include 'sourceResource.temporal.after'
          end
          it "includes $field.distance for a geo_point field" do
            expect(queryable_field_names).to include 'sourceResource.spatial.distance'
          end
          it "does not contain any duplicate fields" do
            expect(queryable_field_names).to match_array queryable_field_names.uniq
          end

        end

        describe "#field" do
          let(:item_mapping) { mock_mapping[resource]['properties'] }

          it "raises an exception for an invalid resource" do
            expect {
              subject.field('fake_resource', 'some_field')
            }.to raise_error /invalid resource: fake_resource/i
          end

          it "creates a top level field with no subfields correctly" do
            fieldstub = double
            name = 'dataProvider'
            Field.should_receive(:new)
              .with(resource,
                    name,
                    item_mapping[name],
                    nil
                    ) { fieldstub }
            expect(subject.field(resource, name)).to eq fieldstub
          end

          it "creates a top level field with subfields correctly" do
            fieldstub = double
            name = 'sourceResource.temporal'
            Field.should_receive(:new)
              .with(resource,
                    name,
                    item_mapping['sourceResource']['properties']['temporal'],
                    nil
                    ) { fieldstub }
            expect(subject.field(resource, name)).to eq fieldstub
          end

          it "creates a subfield field correctly" do
            subfieldstub = double
            name = 'sourceResource.temporal.begin'
            Field.should_receive(:new)
              .with(
                    resource,
                    name,
                    item_mapping['sourceResource']['properties']['temporal']['properties']['begin'],
                    nil
                    ) { subfieldstub }
            expect(subject.field(resource, name)).to eq subfieldstub
          end

          it "passes modifier to Field.new" do
            fieldstub = double
            name = 'dataProvider'
            Field.should_receive(:new)
              .with(resource,
                    name,
                    item_mapping[name],
                    '.some_extra'
                    ) { fieldstub }
            expect(subject.field(resource, name, '.some_extra')).to eq fieldstub
          end

          it "handles mid-level field with subfields" do
            midfield = double
            name = 'sourceResource.level1.level2'
            Field.should_receive(:new)
              .with(
                    resource,
                    name,
                    item_mapping['sourceResource']['properties']['level1']['properties']['level2'],
                    nil
                    ) { midfield }
            expect(subject.field(resource, name)).to eq midfield
          end

          it "handles deeply nested field" do
            subfieldstub = double
            name = 'sourceResource.level1.level2.level3A'
            Field.should_receive(:new)
              .with(
                    resource,
                    name,
                    item_mapping['sourceResource']['properties']['level1']['properties']['level2']['properties']['level3A'],
                    nil
                    ) { subfieldstub }
            expect(subject.field(resource, name)).to eq subfieldstub
          end

          it "returns nil for an invalid top level mapping" do
            name = 'some_invalid_field'
            Field.should_not_receive(:new)
            expect(subject.field(resource, name)).to eq nil
          end 

          it "returns nil for an invalid subfield of an invalid top level mapping" do
            name = 'some_invalid_field.fake_subfield'
            Field.should_not_receive(:new)
            expect(subject.field(resource, name)).to eq nil
          end 

          it "returns nil for an invalid subfield of a valid top level mapping" do
            name = 'level1.invalid_subfield'
            Field.should_not_receive(:new)
            expect(subject.field(resource, name)).to eq nil
          end 

          it "returns nil for an invalid deeply nested subfield of a valid top level mapping" do
            name = 'level1.invalid_subfield.another_invalid_field'
            Field.should_not_receive(:new)
            expect(subject.field(resource, name)).to eq nil
          end 

        end      

      end

    end

  end

end
