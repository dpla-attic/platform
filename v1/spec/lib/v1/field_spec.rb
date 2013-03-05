require 'v1/field'

module V1

  describe Field do
    let(:resource) { 'item' }
    #      let(:type) { 'item' }
    let(:item_mapping) {
      {
        'id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
        'title' => { 'type' => 'string' },
        'description' => { 'type' => 'string' },
        'date' => { 'type' => 'date', 'facet' => true },
        'subject' => {
          'properties' => {
            '@id' => { 'type' => 'string', 'index' => 'not_analyzed' },
            '@type' => { 'type' => 'string', 'index' => 'not_analyzed' },
            'name' => { 'type' => 'string' }
          }
        },
        'multisubject' => {
          'properties' => {
            'name' => {
              'type' => 'multi_field',
              'fields' => {
                'name' => { 'type' => 'string', 'sort' => 'script' },
                'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
              }
            }                      
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
                'not_analyzed' => {'type' => 'string', 'index' => 'not_analyzed', 'facet' => true }
              }
            }
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
        'disabledField' => {
          'enabled' => false
        }
      }
    }
    
    describe "#initialize" do
      let(:name) { 'id' }
      let(:field) { V1::Field.new(resource, name, item_mapping[name]) }

      it "assigns resource param to a .resource attr" do
        expect(field.resource).to eq resource
      end
      it "assigns type param to a .type attr" do
        expect(field.type).to eq 'string'
      end
      it "assigns name param to a .name attr" do
        expect(field.name).to eq name
      end
      it "assigns facet_modifier from params" do
        field = V1::Field.new(resource, name, item_mapping[name], 'extra_info')
        expect(field.facet_modifier).to eq 'extra_info'
      end

      it "returns the type value via its type method" do
        expect(field.type).to eq 'string'
      end
      it "raises an exception when passed a nil mapping" do
        expect {
          V1::Field.new(resource, 'unmapped-field', item_mapping['unmapped-field'])
        }.to raise_error ArgumentError, /^Can't create/i
      end
    end

    describe "type predicates" do
      let(:resource) { 'item' }

      it "implements geo_point?" do
        field = V1::Field.new(
                                      resource,
                                      'spatial.coordinates',
                                      item_mapping['spatial']['properties']['coordinates']
                                      )
        expect(field.geo_point?).to be_true
        field = V1::Field.new(
                                      resource,
                                      'date',
                                      item_mapping['date']
                                      )
        expect(field.geo_point?).to be_false
      end
      it "implements date?" do
        field = V1::Field.new(
                                      resource,
                                      'date',
                                      item_mapping['date']
                                      )
        expect(field.date?).to be_true
      end
      it "implements string?" do
        field = V1::Field.new(
                                      resource,
                                      'title',
                                      item_mapping['title']
                                      )
        expect(field.string?).to be_true
      end
      it "implements multi_field?" do
        field = V1::Field.new(
                                      resource,
                                      'isPartOf.name',
                                      item_mapping['isPartOf']['properties']['name']
                                      )
        expect(field.multi_field?).to be_true
      end
      
    end

    describe "#sortable" do
      it "implements correct sort and sortable? for sort:field" do
        field = V1::Field.new(resource, 'id', item_mapping['id'])
        expect(field.sort).to eq 'field'
        expect(field.sortable?).to be_true
      end
      it "implements correct sort and sortable? for un-sortable field" do
        field = V1::Field.new(resource, 'description', item_mapping['description'])
        expect(field.sort).to eq nil
        expect(field.sortable?).to be_false
      end
      it "implements correct sort and sortable? for multi_field field" do
        field = V1::Field.new(resource, 'multisubject.name', item_mapping['multisubject']['properties']['name'])
        expect(field.multi_field?).to be_true
        
        expect(field.sort).to eq 'script'
        expect(field.multi_field_default.name).to eq 'multisubject.name.name'

        expect(field.sortable?).to be_true
      end
    end

    describe "#multi_fields" do
      it "returns empty array when there are no mult_fields to build" do
        field = V1::Field.new(resource, 'title', item_mapping['title'])
        expect(field.multi_fields).to eq []
      end
      it "returns array of multi_fields when there are one or more multi_fields to build" do
        field = V1::Field.new(resource, 'isPartOf.name', item_mapping['isPartOf']['properties']['name'])
        expect(field.multi_fields.map(&:name)).to match_array %w( isPartOf.name.name isPartOf.name.not_analyzed )
      end
    end

    describe "#subfields" do
      it "returns empty array when there are no subfields to build" do
        field = V1::Field.new(resource, 'title', item_mapping['title'])
        expect(field.subfields).to eq []
      end
      it "returns array of subfields when there are one or more subfields to build" do
        field = V1::Field.new(resource, 'subject', item_mapping['subject'])
        expect(field.subfields.map(&:name)).to match_array %w( subject.@id subject.@type subject.name )
      end
      it "handles subfields for multi_field type" do
        field = V1::Field.new(resource, 'isPartOf', item_mapping['isPartOf'])
        expect(field.subfields.map(&:name)).to match_array %w( isPartOf.@id isPartOf.name )
      end
    end

    describe "#subfields_deep" do
      it "handles field with no subfields" do
        f = V1::Field.new(
                        'item',
                        'spatial.city',
                        item_mapping['spatial']['properties']['city']
                        )

        expect(f.subfields_deep.map(&:name))
          .to match_array( %w( spatial.city ) )
      end
      it "handles 1 level of depth" do
        f = V1::Field.new(
                        'item',
                        'spatial',
                        item_mapping['spatial']
                        )

        expect(f.subfields_deep.map(&:name))
          .to match_array( %w( spatial spatial.city spatial.iso3166-2 spatial.coordinates ) )
      end
      it "handles >1 levels of depth" do
        f = V1::Field.new(
                        'item',
                        'level1',
                        item_mapping['level1']
                        )

        expect(f.subfields_deep.map(&:name))
          .to match_array( %w( level1 level1.level2 level1.level2.level3A level1.level2.level3B ) )
      end
    end

    describe "#subfields?" do
      it "returns false when there are no subfields" do
        field = V1::Field.new(resource, 'title', item_mapping['title'])
        expect(field.subfields?).to be_false
      end
      it "returns array of subfields when there are one or more subfields to build" do
        field = V1::Field.new(resource, 'subject', item_mapping['subject'])
        expect(field.subfields?).to be_true
      end
    end

    describe "#subfield_names" do
      it "returns array of subfield names d" do
        field = V1::Field.new(resource, 'subject', item_mapping['subject'])
        expect(field.subfield_names).to match_array %w( subject.@id subject.@type subject.name )
      end
    end

    describe "#facetable?" do
      context "facetable fields" do
        it "detects a top level simple field" do
          field = V1::Field.new(resource, 'date', item_mapping['date'])
          expect(field.facetable?).to be_true
        end
        it "detects a subfield" do
          field = V1::Field.new(resource, 'spatial.iso3166-2', item_mapping['spatial']['properties']['iso3166-2'])
          expect(field.facetable?).to be_true
        end
        it "detects a multi_field type with a 'not_analyzed' subfield" do
          field = V1::Field.new(resource, 'isPartOf.name', item_mapping['isPartOf']['properties']['name'])
          expect(field.facetable?).to be_true
        end
      end

      context "non-facetable fields" do
        it "detects a top level simple field" do
          field = V1::Field.new(resource, 'title', item_mapping['title'])
          expect(field.facetable?).to be_false
        end
        it "detects a subfield" do
          field = V1::Field.new(resource, 'subject.@id', item_mapping['subject']['properties']['@id'])
          expect(field.facetable?).to be_false
        end
        it "detects a multi_field types with a 'not_analyzed' subfield" do
          field = V1::Field.new(resource, 'field1.name', item_mapping['field1']['properties']['name'])
          expect(field.facetable?).to be_false
        end
      end

    end

    # describe "#analyzed?" do
    #   it "returns false when index => not_analyzed" do
    #     field = V1::Field.new(resource, 'title', item_mapping['title'])
    #     expect(field.analyzed?).to be_true
    #   end
      
    #   it "returns true unless index => not_analyzed" do
    #     field = V1::Field.new(resource, 'id', item_mapping['id'])
    #     expect(field.analyzed?).to be_false
    #   end
    # end

    describe "#enabled?" do
      it "returns false if a field is explicitly not enabled" do
        field = V1::Field.new(resource, 'disabledField', item_mapping['disabledField'])
        expect(field.enabled?).to be_false
      end
    end
  end

end
