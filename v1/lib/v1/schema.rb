require 'v1/schema/field'
require 'v1/searchable/facet'

module V1

  module Schema

    #TODO: finish refactor by using strings for all mapping declarations (:type, etc)
    ELASTICSEARCH_MAPPING = {
      'mappings' => {
        'item' => {
          'properties' => {
            'id' => { :type => 'string', 'index' => 'not_analyzed' },
            '@id' => { :type => 'string', 'index' => 'not_analyzed' },
            'title' => { :type => 'string' },
            'dplaContributor' => {
              'properties' => {
                '@id' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
                'name' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true }
              }
            },
            'creator' => { :type => 'string' },
            'publisher' => { :type => 'string' },
            'created' => { :type => 'date', 'facet' => true },
            'type' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
            'format' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
            'language' => {
              'properties' => {
                'name' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
                'iso639' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true }
              }
            },
            'subject' => {
              'properties' => {
                '@id' => { :type => 'string', 'index' => 'not_analyzed' },
                '@type' => { :type => 'string', 'index' => 'not_analyzed' },
                'name' => { :type => 'string' }
              }
            },
            'description' => { :type => 'string' },
            'rights' => { :type => 'string' },
            'spatial' => {
              'properties' => {
                'name' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
                'state' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
                'city' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
                'iso3166-2' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
                'coordinates' => { :type => "geo_point"}
              }
            },
            'temporal' => {
              'properties' => {
                'start' => { :type => 'date', :null_value => "-9999", 'facet' => true },
                'end'   => { :type => 'date', :null_value => "9999", 'facet' => true }
              }
            },
            'relation' => { :type => 'string' },
            'source' => { :type => 'string' },
            'isPartOf' => {
              'properties' => {
                '@id' => { :type => 'string', 'index' => 'not_analyzed', 'facet' => true },
                'name' => {
                  :type => 'multi_field',
                  'fields' => {
                    'name' => {:type => 'string' },
                    'raw' => {:type => 'string', 'index' => 'not_analyzed', 'facet' => true}
                  }
                }
              }
            },
            'contributor' => { :type => 'string', 'facet' => true },
            'dplaSourceRecord' => {
              # completely omit dplaSourceRecord from the index
              'enabled' => false
            }
          }
        }
      }
    }.freeze

    def self.item_mapping(field=nil)
      mapping('item', field)
    end

    def self.flapping(resource, field)
      # A "resource" is a top-level DPLA resource: 'item', 'collection', 'creator'
      #TODO: base.merge! ELASTICSEARCH_MAPPING['mappings']
      field = field.to_s if field
      #base = ELASTICSEARCH_MAPPING['mappings']
      resourced_mapping = ELASTICSEARCH_MAPPING['mappings'][resource]['properties']

      if field =~ /(.+)\.(.+)/
        # TODO: is this a subfield, or a parent field with a query option?
        # if $field has a mapping
        #   return it
        # else
        #   strip the last word off and see if the remaining string has a mapping
        #   if it does, set that field object's options with whatever we stripped off the end
        #     (.after for a created.after date query, for example.
        #   else
        #     return nil i guess/
        #   end
        # end
        # mapping for a dotted field name: e.g. "spatial.city"

        #TODO: temporary hack to handle $validfield.$some_invalid_subfield situation
        V1::Schema::Field.new(resource, field, resourced_mapping[$1]['properties'][$2]) if resourced_mapping[$1]['properties'] && resourced_mapping[$1]['properties'][$2]
      else
        # mapping for a single field within a single resource
        #base[resource]['properties'][field] rescue nil
        V1::Schema::Field.new(resource, field, resourced_mapping[field]) if resourced_mapping[field]
      end
    end

    def self.mapping(resource=nil, field=nil)
      # A "resource" is a top-level DPLA resource: 'item', 'collection', 'creator'
      #TODO: base = Hash.new { |h, k| h[k] = Hash.new({}) }  # untested
      #TODO: base.merge! ELASTICSEARCH_MAPPING['mappings']
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
      fields = []
      mapping.each do |type, type_mapping|
        type_mapping['properties'].each do |field, field_mapping|
          next if field_mapping.has_key?('enabled') && field_mapping['enabled'] == false

          fields << field

          #top level date fields
          #TODO: use mapping metadata to handle temporal special case
          if field_mapping[:type] == 'date' || field == 'temporal'
            fields << "#{field}.before" << "#{field}.after"
          end

          if field_mapping.has_key? 'properties'
            field_mapping['properties'].each do |subfield, subfield_mapping|
              fields << "#{field}.#{subfield}"

              # support our custom $field.distance query param for all geo_point fields
              if subfield_mapping[:type] == 'geo_point'
                fields << "#{field}.distance"
              end
            end
          end
        end
      end
      fields
    end

    def self.expand_facet_fields(resource, fields)
      # Expands a list of fields into all facetables fields and those fields' facetable subfields
      #TODO: Refactor some this into field.facetable_fields=[]
      #TODO: support wildcard facet '*'
      expanded = []
      fields.each do |field_name|
        field = flapping(resource, field_name)

        new_facets = []
        if field.nil?
          # allow unmapped fields to pass through so they can be handled elsewhere
          new_facets << field_name
        else
          # top level field is facetable
          new_facets << field_name if field.facetable?

          field.subfields.each do |subfield|
            new_facets << "#{field.name}.#{subfield.name}" if subfield.facetable?
          end
        end
        # If nothing has shaken out for this field, persist it so it gets flagged by validation elsehwere
        new_facets << field_name if new_facets.empty?

        expanded << new_facets
      end
      expanded.flatten
    end

  end

end
