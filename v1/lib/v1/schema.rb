module V1

  module Schema

    #TODO: finish refactor by using strings for all mapping declarations (:type, etc)
    ELASTICSEARCH_MAPPING = {
      'mappings' => {
        'item' => {
          'properties' => {
            #NOTE: No longer needed now that the source data uses _id, I think. -phunk
            #:id => { :type => 'string' },
            '@id' => { :type => 'string' },
            'title' => { :type => 'string' },
            'dplaContributor' => {
              'properties' => {
                '@id' => { :type => 'string' },
                'name' => { :type => 'string' }
              }
            },
            'collection' => { :type => 'string' },
            'creator' => { :type => 'string' },
            'publisher' => { :type => 'string' },
            'created' => { :type => 'date' }, #"format" : "YYYY-MM-dd"
            'type' => { :type => 'string' }, #image, text, etc
            'format' => { :type => 'string' }, #mime-type
            'language' => {
              'properties' => {
                'name' => { :type => 'string' },
                'iso639' => { :type => 'string' }
              }
            },
            'subject' => {
              'properties' => {
                '@id' => { :type => 'string' },
                '@type' => { :type => 'string' },
                'name' => { :type => 'string' }
              }
            },
            'description' => { :type => 'string' },
            'rights' => { :type => 'string' },
            'spatial' => {
              'properties' => {
                'name' => { :type => 'string' },
                'state' => { :type => 'string' },
                'city' => { :type => 'string' },
                'iso3166-2' => { :type => 'string' },
                'coordinates' => { :type => "geo_point"}  #, :lat_lon => true, breaks recursive search
              }
            },
            'temporal' => {
              #'type' => 'nested',
              'properties' => {
                'start' => { :type => 'date', :null_value => "-9999" }, #requiredevenifnull #, :format=>"YYYY G"}
                'end'   => { :type => 'date', :null_value => "9999" } #requiredevenifnull
              }
            },
            'relation' => { :type => 'string' },
            'source' => { :type => 'string' },
            'isPartOf' => {
              'properties' => {
                '@id' => { :type => 'string' },
                'name' => { :type => 'string' }
              }
            },
            'contributor' => { :type => 'string' },
            'dplaSourceRecord' => {
              # completely omit dplaSourceRecord from the index for now
              'enabled' => false
              # No dplaSourceRecord subfield should ever get a date mapping (dynamically).
              # If you want to nclude dplaSourceRecord in the index, you can map date
              # fields as strings so it can handle invalid date formats) instead of the
              # (above :enabled => false technique)
              #  :properties => {
              #  :date => { :type => 'string' },
              #  :datestamp => { :type => 'string' }
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

    def self.mapped_fields
      #TODO: memoize
      #TODO: leverage other module methods more
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

  end

end
