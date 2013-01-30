require 'v1/schema/field'

module V1

  module Schema

    ELASTICSEARCH_MAPPING = {
      'mappings' => {
        'item' => {
          'properties' => {
            'id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
            '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
            'title' => { 'type' => 'string', 'sort' => 'script' },
            'dplaContributor' => {
              'properties' => {
                '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
              }
            },
            'creator' => { 'type' => 'string' },
            'publisher' => { 'type' => 'string' },
            'created' => { 'type' => 'date', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
            'type' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
            'format' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
            'language' => {
              'properties' => {
                'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                'iso639' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
              }
            },
            'subject' => {
              'properties' => {
                '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                '@type' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
                'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
              }
            },
            'description' => { 'type' => 'string' },
            'rights' => { 'type' => 'string' },
            'spatial' => {
              'properties' => {
                'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                'state' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                'city' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                'iso3166-2' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                'coordinates' => { 'type' => "geo_point", 'index' => 'not_analyzed', 'sort' => 'geo_distance', 'facet' => true }
              }
            },
            'temporal' => {
              'properties' => {
                'start' => { 'type' => 'date', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true, 'null_value' => '-9999' },
                'end'   => { 'type' => 'date', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true, 'null_value' => '9999' }
              }
            },
            'relation' => { 'type' => 'string' },
            'source' => { 'type' => 'string' },
            'isPartOf' => {
              'properties' => {
                '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                'name' => {
                  'type' => 'multi_field',
                  'fields' => {
                    'name' => {'type' => 'string' },
                    'raw' => {'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true}
                  }
                }
              }
            },
            'contributor' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
            'dplaSourceRecord' => {
              'enabled' => false  # completely omit dplaSourceRecord from the index
            }
          }
        }
      }
    }.freeze

    def self.item_mapping(field=nil)
      mapping('item', field)
    end

    def self.flapping(resource, name, modifier=nil)
      # A "resource" is a top-level DPLA resource: 'item', 'collection', 'creator'
      name = name.to_s

      mapped_fields = ELASTICSEARCH_MAPPING['mappings'][resource]['properties']

      if name =~ /(.+)\.(.+)/
        #TODO:IDEA: We could strip of trailing dotted modifiers (e.g. created.year) to get down to
        # a valid field, then store that modifier string in the Field instance...

        #TODO: temporary hack to handle $validfield.$some_invalid_subfield situation
        if mapped_fields[$1] && mapped_fields[$1]['properties'] && mapped_fields[$1]['properties'][$2]
          # This is a subfield
          return V1::Schema::Field.new(resource, name, mapped_fields[$1]['properties'][$2], modifier)
        end
      else
        # mapping for a top-level field
        if mapped_fields[name]
          return V1::Schema::Field.new(resource, name, mapped_fields[name], modifier)
        end
      end
    end

    def self.mapping(resource=nil, field=nil)
      # A "resource" is a top-level DPLA resource: 'item', 'collection', 'creator'
      base = ELASTICSEARCH_MAPPING['mappings']

      # Standardize on strings
      resource = resource.to_s if resource
      field = field.to_s if field

      if resource.nil?
        # mapping for all resources
        base
      elsif field.nil?
        # mapping for a single resource
        base[resource]['properties'] rescue nil
      elsif field =~ /(.+)\.(.+)/
        # mapping for a dotted field name: e.g. "spatial.city"
        base[resource]['properties'][$1]['properties'][$2] rescue nil
      else
        # mapping for a single field within a single resource
        base[resource]['properties'][field] rescue nil
      end
    end

    def self.queryable_fields
      # Renders mapping into a list of fields and $field.subfields
      #TODO: Refactor to use Field class and subfields
      fields = []
      mapping.each do |type, type_mapping|
        type_mapping['properties'].each do |field, field_mapping|
          next if field_mapping.has_key?('enabled') && field_mapping['enabled'] == false

          fields << field

          #top level date fields
          #TODO: use mapping metadata to handle temporal special case
          if field_mapping['type'] == 'date' || field == 'temporal'
            fields << "#{field}.before" << "#{field}.after"
          end

          if field_mapping.has_key? 'properties'
            field_mapping['properties'].each do |subfield, subfield_mapping|
              fields << "#{field}.#{subfield}"

              # support our custom $field.distance query param for all geo_point fields
              if subfield_mapping['type'] == 'geo_point'
                fields << "#{field}.distance"
              end
            end
          end
        end
      end
      fields
    end

  end

end
