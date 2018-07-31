require_relative 'field'

module V1

  module Schema
    
    ELASTICSEARCH_MAPPING = {
      'collection' => {
        'properties' => {
          '@id' => { 'type' => 'keyword', 'sort' => 'field' },
          'description' => { 'type' => 'text' },
          'id' => { 'type' => 'keyword', 'sort' => 'field' },
          'title' => {
            'fields' => {
              'title' => { 'type' => 'text', 'sort' => 'multi_field' },
              'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
            }
          }
        }
      },  #/collection
      'item' => {
        'properties' => {
          '@id' => { 'type' => 'keyword', 'sort' => 'field' },
          'admin' => {
            'properties' => {
              'contributingInstitution' => {
                'type' => 'keyword',
                'enabled' => false,
                'include_in_all' => false,
                'facet' => true
              }
            }
          },
          'id' => { 'type' => 'keyword', 'sort' => 'field' },
          'sourceResource' => {
            'properties' => {
              'identifier' => { 'type' => 'keyword', 'sort' => 'field' },
              'collection' => {
                'properties' => {
                  '@id' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
                  'id' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
                  'description' => { 'type' => 'text' },
                  'title' => {
                    'fields' => {
                      'title' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  }
                }
              },
              'contributor' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
              'creator' => { 'type' => 'text' },
              'date' => {
                'properties' => {
                  'displayDate' =>  { 'type' => 'text'},
                  'begin' => {
                    'fields' => {
                      'begin' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '-9999', 'ignore_malformed' => true },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true, 'ignore_malformed' => true }
                    }
                  },
                  'end' => {
                    'fields' => {
                      'end' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '9999', 'ignore_malformed' => true },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true, 'ignore_malformed' => true }
                    }
                  }
                }
              },
              'description' => { 'type' => 'text' },
              'extent' => { 'type' => 'keyword', 'sort' => 'field' },
              'isPartOf' => { 'enabled' => false },
              'language' => {
                'properties' => {
                  'name' => {
                    'fields' => {
                      'name' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true },
                    }
                  },
                  'iso639_3' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true }
                }
              },
              'format' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
              'publisher' => {
                'fields' => {
                  'publisher' => { 'type' => 'text' },
                  'not_analyzed' => { 'type' => 'keyword', 'facet' => true }
                }
              },
              'rights' => { 'type' => 'text' },
              'relation' => { 'type' => 'text' },
              'spatial' => {
                'properties' => {
                  'name' => {
                    'fields' => {
                      'name' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'country' => {
                    'fields' => {
                      'country' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'region' => {
                    'fields' => {
                      'region' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'county' => {
                    'fields' => {
                      'county' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'state' => {
                    'fields' => {
                      'state' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'city' => {
                    'fields' => {
                      'city' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  },
                  'iso3166-2' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
                  'coordinates' => { 'type' => 'geo_point', 'sort' => 'geo_distance', 'facet' => true }
                }
              },
              'specType' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
              'subject' => {
                'properties' => {
                  '@id' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
                  '@type' => { 'type' => 'keyword', 'sort' => 'field' },
                  'name' => {
                    'fields' => {
                      'name' => { 'type' => 'text', 'sort' => 'multi_field' },
                      'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                    }
                  }
                }
              },
              'temporal' => {
                'properties' => {
                  'begin' => {
                    'fields' => {
                      'begin' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '-9999', 'ignore_malformed' => true },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true, 'ignore_malformed' => true }
                    }
                  },
                  'end' => {
                    'fields' => {
                      'end' => { 'type' => 'date', 'sort' => 'multi_field', 'null_value' => '9999', 'ignore_malformed' => true },
                      'not_analyzed' => { 'type' => 'date', 'sort' => 'field', 'facet' => true, 'ignore_malformed' => true }
                    }
                  }

                }
              },
              'title' => {
                'fields' => {
                  'title' => { 'type' => 'text', 'sort' => 'multi_field'},
                  'not_analyzed' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => false }
                }
              },
              'type' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
            }
          },  #/sourceResource
          'dataProvider' => {
            'fields' => {
              'dataProvider' => { 'type' => 'text', 'sort' => 'multi_field' },
              'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
            }
          },
          'hasView' => {
            'properties' => {
              '@id' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
              'format' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true },
              'rights' => { 'type' => 'keyword' },
              'edmRights' => { 
                'fields' => {
                  'edmRights' => { 'type' => 'text', 'sort' => 'multi_field' },
                  'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                }
              }
            }
          },
          'intermediateProvider' => {
            'fields' => {
              'intermediateProvider' => { 'type' => 'text', 'sort' => 'multi_field' },
              'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
            }
          },
          'isPartOf' => {
            'properties' => {
              '@id' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
              'name' => {
                'fields' => {
                  'name' => { 'type' => 'text', 'sort' => 'multi_field' },
                  'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                }
              }                      
            }
          },
          'isShownAt' => { 'type' => 'keyword', 'sort' => 'field' },
          'object' => { 'type' => 'keyword', 'sort' => 'field' },
          'provider' => {
            'properties' => {
              '@id' => { 'type' => 'keyword', 'sort' => 'field', 'facet' => true },
              'name' => {
                'fields' => {
                  'name' => { 'type' => 'text', 'sort' => 'multi_field' },
                  'not_analyzed' => { 'type' => 'keyword', 'sort' => 'script', 'facet' => true }
                }
              }                      
            }
          },
          'rights' => { 'type' => 'text' }
        }
      }  #/item
    }.freeze

    def self.full_mapping
      ELASTICSEARCH_MAPPING
    end

    ##
    # Return a V1::Field corresponding to the given field name, or nil if the
    # name does not correspond to a field.
    #
    # There are request parameters (e.g. "sort_by" or "callback") that are not
    # field names. This method returns nil in those cases.
    #
    # @see V1::Searchable::Query.string_queries, where it evaluates whether
    #      field.nil?
    #
    # @return [V1::Field] or [nil]
    def self.field(resource, name, modifier=nil)
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
