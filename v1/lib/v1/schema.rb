require 'v1/field'

module V1

  module Schema
    
    ELASTICSEARCH_MAPPING = {
      'item' => {
        'date_detection' => false,
        'properties' => {
          'id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          '@context' => { 'type' => 'object', 'enabled' => false },
          'admin' => { 'type' => 'object', 'enabled' => false },
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
          'originalRecord' => { 'type' => 'object', 'enabled' => false },
          'provider' => {
            'properties' => {
              '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
            }
          }
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

      #init starting point for the mapping traversal.
      current_mapping = ELASTICSEARCH_MAPPING[resource]['properties'][first_name]

      field_names.each do |word|
        # the rescue nil handles invalid field names at any level
        current_mapping = current_mapping['properties'][word] rescue nil
      end

      return V1::Field.new(resource, name, current_mapping, modifier) if current_mapping
    end

    def self.queryable_fields
      # Renders mapping into a list of fields and $field.subfields
      resource = 'item'
      names = []
      top_level_names = ELASTICSEARCH_MAPPING[resource]['properties'].keys
      
      top_level_names.each do |name|
        field = V1::Schema.field(resource, name)
        next unless field.enabled?

        names << field.name

        field.subfields_deep.each do |subfield|
          names << subfield.name
          
          # special handling for date ranges on this subfield's parent field name
          if subfield.date?
            names << subfield.name.gsub(/\.end$/, '.after')
            names << subfield.name.gsub(/\.begin$/, '.before')
          elsif subfield.geo_point?
            names << subfield.name.gsub(/^(.+)\.(.+)$/, '\1.distance')
          end
        end
      end
      names
    end

    # def self.mapping(resource=nil, field=nil)
    #   #TODO: DEPRECATED
    #   # A "resource" is a top-level DPLA resource: 'item', 'collection', 'creator'
    #   base = ELASTICSEARCH_MAPPING

    #   # Standardize on strings
    #   resource = resource.to_s if resource
    #   field = field.to_s if field

    #   if resource.nil?
    #     # mapping for all resources
    #     base
    #   elsif field.nil?
    #     # mapping for a single resource
    #     base[resource]['properties'] rescue nil
    #   elsif field =~ /(.+)\.(.+)/
    #     # mapping for a dotted field name: e.g. "spatial.city"
    #     base[resource]['properties'][$1]['properties'][$2] rescue nil
    #   else
    #     # mapping for a single field within a single resource
    #     base[resource]['properties'][field] rescue nil
    #   end
    # end



  end

end
