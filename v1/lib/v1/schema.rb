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

    def self.mapping(type=nil, field=nil)
      # A "type" is a top-level DPLA resource: 'item', 'collection', 'creator'
      #TODO: base = Hash.new { |h, k| h[k] = Hash.new({}) }  # untested
      #TODO: base.merge! ELASTICSEARCH_MAPPING['mappings']
      base = ELASTICSEARCH_MAPPING['mappings']

      # Standardize on strings
      type = type.to_s if type
      field = field.to_s if field

      if type.nil?
        # mapping for all types
        base
      elsif field.nil?
        # mapping for a single type
        base[type]['properties'] rescue nil
      elsif field =~ /(.+)\.(.+)/
        # mapping for a dotted field name: e.g. "spatial.city"
        base[type]['properties'][$1]['properties'][$2] rescue nil
      else
        # mapping for a single field within a single type
        base[type]['properties'][field] rescue nil
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

    def self.facetable?(type, field)
      mapping = mapping(type, field)

      return false unless mapping

      # facetable field or subfield
      return true if mapping['facet']

      # facetable multi_field subfield
      if mapping[:type] == 'multi_field' && mapping['fields']
        return mapping['fields']['raw'] && mapping['fields']['raw']['facet']
      end

      false
    end

    def self.expand_facet_fields(type, fields)
      # Expands a list of fields into all facetables fields and those fields' facetable subfields
      #TODO: Refactor facet related method into Searchable::Facet
      #TODO: support wildcard facet '*'
      expanded = []
      fields.each do |field|
        new_facets = []
        mapping = mapping(type, field)

        # allow unmapped fields to pass through so they can be handled elsewhere
        new_facets << field if mapping.nil?

        # top level field is facetable
        new_facets << field if facetable?(type, field)

        if mapping && mapping['properties']
          mapping['properties'].each do |subfield, subfield_mapping|
            new_facets << "#{field}.#{subfield}" if facetable?(type, "#{field}.#{subfield}")
          end
        end

        # If nothing has shaken out for this field, persist it so it gets flagged by validation elsehwere
        new_facets << field if new_facets.empty?

        expanded << new_facets
      end
      expanded.flatten
    end

    def self.facet_field(field)
      # Conditionally extend multi_field types to their .raw sub-field.
      mapping = mapping('item', field)

      if !mapping && field =~ /(.+)\.(.*)$/ && V1::Searchable::Facet::DATE_INTERVALS.include?($2)
        return $1
      end

      if mapping[:type] == 'multi_field' && mapping['fields']['raw'] && mapping['fields']['raw']['facet']
        field + '.raw'
      else
        field
      end
    end
  end

end
