require_relative 'field'

module V1

  module Schema
    
    ELASTICSEARCH_MAPPING = {
      'collection' => {
        'date_detection' => false,
        'properties' => {
          '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          'admin' => {
            'properties' => {
              'validate_on_enrich' => { 'type' => 'boolean'},
              'ingestType' => { 'enabled' => false },
              'ingestDate' => { 'type' => 'date' },
            }
          },
          'description' => { 'type' => 'string' },
          'id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          'title' => {
            'type' => 'multi_field',
            'fields' => {
              'title' => { 'type' => 'string', 'sort' => 'multi_field' },
              'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
            }
          },
          'ingestType' => { 'enabled' => false },
          'ingestDate' => { 'enabled' => false },
          '_rev' => { 'enabled' => false },
        }
      },  #/collection
      'item' => {
        'date_detection' => false,
        'properties' => {
          '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          'admin' => {
            'properties' => {
              'sourceResource' => {  #shadow_sort fields
                'properties' => {
                  'title' => { 'type' => 'string', 'analyzer' => 'canonical_sort', 'null_value' => 'zzzzzzzz' },
                }
              },
              'validate_on_enrich' => { 'type' => 'boolean'},
              'ingestType' => { 'enabled' => false },
              'ingestDate' => { 'type' => 'date' },
            }
          },
          'id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          'sourceResource' => {
            'properties' => {
              'identifier' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
              'collection' => {
                'properties' => {
                  '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'description' => { 'type' => 'string' },
                  'title' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'title' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  }
                }
              },
              'contributor' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'creator' => { 'type' => 'string' },
              'date' => {
                'properties' => {
                  'displayDate' =>  { 'type' => 'string', 'index' => 'not_analyzed'},
                  'begin' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'begin' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '-9999' },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true }
                    }
                  },
                  'end' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'end' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '9999' },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true }
                    }
                  }
                }
              },
              'description' => { 'type' => 'string' },
              'extent' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
              'isPartOf' => { 'enabled' => false },
              'language' => {
                'properties' => {
                  'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'iso639' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
                }
              },
              'format' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'publisher' => {
                'type' => 'multi_field',
                'fields' => {
                  'publisher' => { 'type' => 'string' },
                  'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'facet' => true }
                }
              },
              'rights' => { 'type' => 'string' },
              'relation' => { 'type' => 'string' },
              'spatial' => {
                'properties' => {
                  'name' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'name' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'country' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'country' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'region' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'region' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'county' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'county' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'state' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'state' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'city' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'city' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'iso3166-2' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'coordinates' => { 'type' => 'geo_point', 'index' => 'not_analyzed', 'sort' => 'geo_distance', 'facet' => true }
                }
              },
              'specType' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'stateLocatedIn' => {
                'properties' => {
                  'name' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  'iso3166-2' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true }
                }
              },
              'subject' => {
                'properties' => {
                  '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
                  '@type' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
                  'name' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'name' => { 'type' => 'string', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                    }
                  }
                }
              },
              'temporal' => {
                'properties' => {
                  'begin' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'begin' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '-9999' },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true }
                    }
                  },
                  'end' => {
                    'type' => 'multi_field',
                    'fields' => {
                      'end' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '9999' },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true }
                    }
                  }

                }
              },
              'title' => { 'type' => 'string', 'sort' => 'shadow' },
              'type' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
            }
          },  #/sourceResource
          'dataProvider' => {
            'type' => 'multi_field',
            'fields' => {
              'dataProvider' => { 'type' => 'string', 'sort' => 'multi_field' },
              'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
            }
          },
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
              'name' => {
                'type' => 'multi_field',
                'fields' => {
                  'name' => { 'type' => 'string', 'sort' => 'multi_field' },
                  'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                }
              }                      
            }
          },
          'isShownAt' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          'object' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field' },
          'provider' => {
            'properties' => {
              '@id' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'field', 'facet' => true },
              'name' => {
                'type' => 'multi_field',
                'fields' => {
                  'name' => { 'type' => 'string', 'sort' => 'multi_field' },
                  'not_analyzed' => { 'type' => 'string', 'index' => 'not_analyzed', 'sort' => 'script', 'facet' => true }
                }
              }                      
            }
          },
          '@context' => { 'type' => 'object', 'enabled' => false },
          'originalRecord' => { 'type' => 'object', 'enabled' => false },
          'ingestType' => { 'enabled' => false },
          'ingestDate' => { 'enabled' => false },
          '_rev' => { 'enabled' => false },
        }
      }  #/item
    }.freeze

    def self.full_mapping
      ELASTICSEARCH_MAPPING
    end

    def self.field(resource, name, modifier=nil)
      # A "resource" is a top-level DPLA resource: 'item', 'collection', 'creator'
      # TODO: memoize a hash value for every $name and return it if it exists. The modifier
      # is a concern, though.
      raise "Invalid resource: #{resource}" unless full_mapping[resource]

      current_mapping = full_mapping[resource]

      name.split('.').each do |word|
        # the rescue nil handles invalid field names at any level
        current_mapping = current_mapping['properties'][word] rescue nil
      end

      return Field.new(resource, name, current_mapping, modifier) if current_mapping
    end

    def self.all_fields(resource)
      # Renders mapping into a list of fields and $field.subfields. This will include
      # every node in the mapping, meaning node "levelA" will be included even if
      # it has subfields.
      names = {}
      
      full_mapping[resource]['properties'].keys.each do |name|
        field = Schema.field(resource, name)
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
        
        # Special handling for straight date or multi_field->date fields
        if field.date? || field.multi_field_date?
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
