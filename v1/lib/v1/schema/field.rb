require 'v1/schema'

module V1

  module Schema

    class Field
      #  USE CASES: 
      # f = flapping('item', field)
      #   calls Field.new with ^^^ that hash. Field.new will call itself for any subfields
      # #return nil if this field is unmapped. Otherwise, perhaps a f.unmapped? predicate.
      #@ f.type
      #@ f.name (e.g. id, subject, spatial.city)
      #@ f.to_s  # => subject.name  #works for fields and subfields
      #@ f.subfields   # => array of field instances for its subfields
      #@ f.subfields?  # true if it has any 
      #@ f.analyzed?  
      #@ f.facetable?  # true if it is. :)
      # f.facet_name  # => isPartOf.name => isPartOf.name.raw (it's multi_field)
      # f.facet_fields# results of expand_facet_name (always returns an array)
      # f.options (?) # query params appended to field name (e.g. created.before)

      attr_reader :resource, :name, :type
      
      def initialize(resource, name, mapping)
        if mapping.nil?
          raise ArgumentError, "Can't create #{self.class} instance from nil mapping param"
        end
        
        @resource = resource
        @name = name
        # @parent_name...
        @mapping = mapping
        @type = mapping[:type]
      end

      def subfields?
        self.subfields.any?
      end

      def subfields
        # handles normal fields and multi_field types
        @subfields ||= map_fields(@mapping['properties'])
      end

      def multi_fields
        @multi_fields ||= build_multi_fields
      end

      def build_multi_fields
        type == 'multi_field' ? map_fields(@mapping['fields']) : []
      end

      def map_fields(mapping)
        if mapping
          mapping.map do |name, mapping|
            self.class.new(@resource, name, mapping)
          end
        else
          []
        end
      end

      def facetable?
        # Rules: a field is facetable if its 'facet' attribute is true, or if its type is
        # multi_field and it has a multi_field named 'raw' that is facetable?. This could
        # be set up to look for the multi_field with the same name as this field, too. 
        # We just don't have anything mapped like that yet.
        if @mapping['facet']
          # this is a facetable field or subfield
          true
        elsif type == 'multi_field'
          # this has a facetable multi_field subfield
          multi_fields.select {|mf| mf.name == 'raw' && mf.facetable?}.any?
        else
          false
        end
      end

      def analyzed?
        @mapping['index'] != 'not_analyzed'
      end

    end

  end

end

