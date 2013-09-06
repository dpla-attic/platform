module V1

  class Field

    attr_reader :resource, :name, :facet_modifier
    
    def initialize(resource, name, mapping, facet_modifier=nil)
      if mapping.nil?
        raise ArgumentError, "Can't create #{self.class} instance from nil mapping param"
      end

      @resource = resource
      @name = name
      @mapping = mapping

      # facet_modifier is any extra text that modifies how this field is used as a facet
      @facet_modifier = facet_modifier
    end

    def type
      @mapping['type']
    end

    def simple_name
      @simple_name ||= name.split('.').last
    end

    def sort
      # the type of sort to use for this field, nil if !sortable?
      @mapping['sort'] || multi_field_default && multi_field_default.sort
    end

    def sortable?
      !!sort || multi_field_default && multi_field_default.sortable?
    end

    def multi_field_default
      # the field ElasticSearch uses as the "default" sub-multi_field for this field
      # e.g. "sourceResource.collection.title" => "sourceResource.collection.title.title"
      return @multi_field_default if defined?(@multi_field_default)
      @multi_field_default = multi_fields.detect {|mf| mf.simple_name == simple_name }
    end

    def subfields?
      self.subfields.any?
    end

    def subfields
      @subfields ||= mapping_to_fields(@mapping['properties'])
    end

    def subfields_deep
      # Note: As a side-effect of the recursive design this will always return self
      # for a field with no subfields
      [self] + subfields.map(&:subfields_deep).flatten
    end

    def subfield_names
      subfields.map(&:name)
    end

    def multi_fields
      @multi_fields ||= build_multi_fields
    end

    def build_multi_fields
      multi_field? ? mapping_to_fields(@mapping['fields']) : []
    end

    def mapping_to_fields(mapping)
      return [] unless mapping
      mapping.map do |name, mapping|
        self.class.new(@resource, "#{@name}.#{name}", mapping)
      end
    end

    def facetable?
      # Rules: a field is facetable if its 'facet' attribute is true, or if its type is
      # multi_field and it has a multi_field named 'not_analyzed' that is facetable?. This could
      # be set up to look for the multi_field with the same name as this field, too. 
      # Note: A field is not facetable if its facetable attribute is false but it does
      # have a facetable subfield - you would need to expand this field to get its facetable
      # subfields in that situation.
      if @mapping['facet']
        true
      elsif multi_field?
        not_analyzed_field && not_analyzed_field.facetable?
      else
        false
      end
    end

    def not_analyzed_field
      return nil unless multi_field?
      multi_fields.detect {|mf| mf.name == name + '.not_analyzed'}
    end

    def analyzed?
      @mapping['index'] != 'not_analyzed'
    end

    def enabled?
      !(@mapping.has_key?('enabled') && @mapping['enabled'] == false)
    end

    def geo_point?
      type == 'geo_point'
    end

    def date?
      type == 'date'
    end

    def string?
      type == 'string'
    end

    def multi_field?
      type == 'multi_field'
    end

    def multi_field_date?
      # aka "a date field wrapped in a multi_field"
      multi_field? && multi_field_default && multi_field_default.date?
    end
  end

end

