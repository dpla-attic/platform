require 'v1/field'

module V1

  module Schema
    
    ELASTICSEARCH_MAPPING = {
      'item' => {
        'date_detection' => false,
        'properties' => {
          'id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          'aggregatedCHO' => {
            'properties' => {
              'contributor' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'creator' => { 'type' => 'string' },
              'date' => {
                'properties' => {
                  'displayDate' =>  { 'type' => 'string', 'index' => 'not_analyzed'},
                  'begin' => { 'type' => 'date', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true, 'null_value' => '-9999' },
                  'end' => { 'type' => 'date', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true, 'null_value' => '9999' }
                }
              },
              'description' => { 'type' => 'string' },
              'extent' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
              'language' => {
                'properties' => {
                  'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'iso639' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
                }
              },
              'physicalMedium' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'publisher' => { 'type' => 'string' },
              'rights' => { 'type' => 'string' },
              'relation' => { 'type' => 'string' },
              'stateLocatedIn' => {
                'properties' => {
                  'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'iso3166-2' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
                }
              },
              'spatial' => {
                'properties' => {
                  'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'country' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'region' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'county' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'state' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'city' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'iso3166-2' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'coordinates' => { 'type' => 'geo_point', 'index' => 'not_analyzed', 'sort' => 'geo_distance', 'facet' => true }
                }
              },
              'subject' => {
                'properties' => {
                  '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  '@type' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
                  'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                }
              },
              'temporal' => {
                'properties' => {
                  'begin' => { 'type' => 'date', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true, 'null_value' => '-9999' },
                  'end'  => { 'type' => 'date', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true, 'null_value' => '9999' }
                }
              },
              'title' => { 'type' => 'string', 'sort' => 'script' },
              'type' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
            }
          },  #/aggregatedCHO
          'dataProvider' => { 'type' => 'string' },
          'hasView' => {
            'properties' => {
              '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'format' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true },
              'rights' => { 'type' => 'string', 'index' => 'not_analyzed' }
            }
          },
          'isPartOf' => {
            'properties' => {
              '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
            }
          },
          'isShownAt' => {
            'properties' => {
              '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'format' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true },
              'rights' => { 'type' => 'string', 'index' => 'not_analyzed' }
            }
          },
          'object' => {
            'properties' => {
              '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'format' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true },
              'rights' => { 'type' => 'string', 'index' => 'not_analyzed' }
            }
          },
          'provider' => {
            'properties' => {
              '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
            }
          },
          '@context' => { 'type' => 'object', 'enabled' => false },
          'admin' => { 'type' => 'object', 'enabled' => false },
          'originalRecord' => { 'type' => 'object', 'enabled' => false },
          'ingestType' => { 'type' => 'string', 'include_in_all' => false },
          'ingestDate' => { 'type' => 'date', 'include_in_all' => false },
        }
      }
    }.freeze

    def self.field(resource, name, modifier=nil)
      # A "resource" is a top-level DPLA resource: 'item', 'collection', 'creator'

      if !ELASTICSEARCH_MAPPING.has_key? resource
        raise "Invalid resource: #{resource}"
      end

      field_names = name.split('.')
      first_name = field_names.shift

      #TODO: skip shift and just start current_mapping at ...[resource].
      #init starting point for the mapping traversal.
      current_mapping = ELASTICSEARCH_MAPPING[resource]['properties'][first_name]

      field_names.each do |word|
        # the rescue nil handles invalid field names at any level
        current_mapping = current_mapping['properties'][word] rescue nil
      end

      return V1::Field.new(resource, name, current_mapping, modifier) if current_mapping
    end

    def self.all_fields(resource)
      # Renders mapping into a list of fields and $field.subfields. This will include
      # every node in the mapping, meaning level1 will be included even if
      # it has subfields.
      names = {}
      top_level_names = ELASTICSEARCH_MAPPING[resource]['properties'].keys
      
      top_level_names.map do |name|
        field = V1::Schema.field(resource, name)
        next unless field.enabled?

        names[field.name] = field

        field.subfields_deep.each do |subfield|
          names[subfield.name] = subfield
        end
      end
      names.values
    end

    def self.queryable_field_names(resource)
      # Renders mapping into a list of fields, $field.subfields, AND any additional
      # query params that can be extrapolated from certain field types.

      names = []
      all_fields(resource).each do |field|
        names << field.name
        # special handling for date ranges on this subfield's parent field name
        if field.date?
          names << field.name.sub(/\.end$/, '.after') if field.name =~ /\.end$/
          names << field.name.sub(/\.begin$/, '.before') if field.name =~ /\.begin$/
        elsif field.geo_point?
          names << field.name.sub(/^(.+)\.(.+)$/, '\1.distance')
        end
      end
      names
    end

  end

end
