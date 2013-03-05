module V1

  class Field
    # f.facet_name  # => isPartOf.name => isPartOf.name.not_analyzed (its multi_field)
    # f.facet_fields# results of expand_facet_name (always returns an array)
    # f.options (?) # query params appended to field name (e.g. date.before)

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

    #TODO: Right now, sorting on a multi_field happens on its multi_field_default. Ideally,
    # this would be changed to its not_analyzed field. Then the sort attr on the multi_field_default
    # can be removed
    def sort  #TEST
      #TODO: multi_field support
      @mapping['sort'] || multi_field_default && multi_field_default.sort
    end

    def simple_name
      @simple_name ||= name.split('.').last
    end

    def sortable?  #TEST
      !!sort || multi_field_default && multi_field_default.sortable?
    end

    def multi_field_default  #TEST
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
      type == 'multi_field' ? mapping_to_fields(@mapping['fields']) : []
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
        # this is a facetable field or subfield
        true
      elsif type == 'multi_field'
        # this has a facetable multi_field subfield
        multi_fields.select {|mf| mf.name =~ /\.not_analyzed$/ && mf.facetable?}.any?
      else
        false
      end
    end

    # def analyzed?
    #   @mapping['index'] != 'not_analyzed'
    # end

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

  end

end

