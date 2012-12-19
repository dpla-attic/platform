require 'v1/schema/field'

module V1

  module Schema

    describe Field do
      let(:type) { 'item' }
      let(:item_mapping) {
        {
          'id' => { :type => 'string', 'index' => 'not_analyzed' },
          'title' => { :type => 'string' },
          'created' => { :type => 'date', 'facet' => true },
          'subject' => {
            'properties' => {
              '@id' => { :type => 'string', 'index' => 'not_analyzed' },
              '@type' => { :type => 'string', 'index' => 'not_analyzed' },
              'name' => { :type => 'string' }
            }
          },
          'spatial' => {
            'properties' => {
              'city' => { :type => 'string', 'index' => "not_analyzed" },
              'iso3166-2' => { :type => 'string', :index => 'not_analyzed', 'facet' => true },
              'coordinates' => { :type => "geo_point" }
            }
          },
          'isPartOf' => {
            'properties' => {
              '@id' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
              'name' => {
                :type => 'multi_field',
                'fields' => {
                  'name' => {:type => 'string' },
                  'raw' => {:type => 'string', 'index' => 'not_analyzed', 'facet' => true }
                }
              }
            }
          },
          'field1' => {
            'properties' => {
              'name' => {
                :type => 'multi_field',
                'fields' => {
                  'name' => {:type => 'string', 'index' => 'analyzed' }
                }
              }
            }
          }
        }
      }
      
      describe "#facetable?" do
        context "facetable fields" do
          it "detects a top level simple field" do
            field = V1::Schema::Field.new(type, 'created', item_mapping['created'])
            expect(field.facetable?).to be_true
          end
          it "detects a subfield" do
            field = V1::Schema::Field.new(type, 'spatial.iso3166-2', item_mapping['spatial']['properties']['iso3166-2'])
            expect(field.facetable?).to be_true
          end
          it "detects a multi_field type with a 'raw' subfield" do
            field = V1::Schema::Field.new(type, 'isPartOf.name', item_mapping['isPartOf']['properties']['name'])
            expect(field.facetable?).to be_true
          end
        end

        context "non-facetable fields" do
          it "detects a top level simple field" do
            field = V1::Schema::Field.new(type, 'title', item_mapping['title'])
            expect(field.facetable?).to be_false
          end
          it "detects a subfield" do
            field = V1::Schema::Field.new(type, 'subject.@id', item_mapping['subject']['properties']['@id'])
            expect(field.facetable?).to be_false
          end
          it "detects a multi_field types with a 'raw' subfield" do
            field = V1::Schema::Field.new(type, 'field1.name', item_mapping['field1']['properties']['name'])
            expect(field.facetable?).to be_false
          end
        end

      end

      describe "#initialize" do
        let(:resource) { 'item' }
        let(:name) { 'title' }
        let(:field) { V1::Schema::Field.new(resource, name, item_mapping[name]) }

        it "assigns resource param to a .resource attr" do
          expect(field.resource).to eq resource
        end
        it "assigns type param to a .type attr" do
          expect(field.type).to eq 'string'
        end
        it "assigns name param to a .name attr" do
          expect(field.name).to eq name
        end
        it "raises an exception when passed a nil mapping" do
          expect {
            V1::Schema::Field.new(resource, 'unmapped-field', item_mapping['unmapped-field'])
          }.to raise_error ArgumentError, /^Can't create/i
        end
        
      end
      # 'isPartOf' => {
      #   'properties' => {
      #     '@id' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
      #     'name' => {
      #       :type => 'multi_field',
      #       'fields' => {
      #         'name' => {:type => 'string' },
      #         'raw' => {:type => 'string', 'index' => 'not_analyzed', 'facet' => true }
      #       }
      #     }
      #   }
      # },

      describe "#multi_fields" do
        it "returns empty array when there are no mult_fields to build" do
          field = V1::Schema::Field.new(type, 'title', item_mapping['title'])
          expect(field.multi_fields).to eq []
        end
        it "returns array of multi_fields when there are one or more multi_fields to build" do
          field = V1::Schema::Field.new(type, 'isPartOf.name', item_mapping['isPartOf']['properties']['name'])
          expect(field.multi_fields.map(&:name)).to match_array %w( name raw )
        end
      end

      describe "#subfields" do
        it "returns empty array when there are no subfields to build" do
          field = V1::Schema::Field.new(type, 'title', item_mapping['title'])
          expect(field.subfields).to eq []
        end
        it "returns array of subfields when there are one or more subfields to build" do
          field = V1::Schema::Field.new(type, 'subject', item_mapping['subject'])
          expect(field.subfields.map(&:name)).to match_array %w( @id @type name )
        end
        it "handles subfields for multi_field type" do
          field = V1::Schema::Field.new(type, 'isPartOf', item_mapping['isPartOf'])
          expect(field.subfields.map(&:name)).to match_array %w( @id name )
        end
      end
      
      describe "#subfields?" do
        it "returns false when there are no subfields" do
          field = V1::Schema::Field.new(type, 'title', item_mapping['title'])
          expect(field.subfields?).to be_false
        end
        it "returns array of subfields when there are one or more subfields to build" do
          field = V1::Schema::Field.new(type, 'subject', item_mapping['subject'])
          expect(field.subfields?).to be_true
        end
      end

    end

  end

end
