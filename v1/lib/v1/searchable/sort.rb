require_relative '../schema'
require_relative '../search_error'

module V1

  module Searchable

    module Sort

      # Default sort order for search results
      DEFAULT_SORT_ORDER = 'asc'
      VALID_SORT_ORDERS = %w( asc desc )

      def self.build_sort(resource, search, params)
        sort_attrs = build_sort_attributes(resource, params)
        search.sort { by(sort_attrs) }
      end

      def self.sort_order(params)
        raw_order = params['sort_order'].to_s
        order = raw_order.downcase

        if order == ''
          default_sort_order
        elsif valid_sort_orders.include?(order)
          order
        else
          raise BadRequestSearchError, "Invalid sort_order value: #{raw_order}"
        end
      end

      def self.sort_by(resource, field_name)
        sort_by = Schema.field(resource, field_name)
        
        if sort_by.nil?
          raise BadRequestSearchError, "Invalid field(s) specified in sort_by parameter: #{field_name}"
        end

        if !sort_by.sortable?
          raise BadRequestSearchError, "Non-sortable field(s) specified in sort_by parameter: #{field_name}"
        end

        if sort_by.sort == 'multi_field'
          sort_by = sort_by.not_analyzed_field
          
          if sort_by.nil?
            raise InternalServerSearchError, "multi_field sort attribute missing not_analyzed sibling"
          end
        end

        sort_by
      end

      def self.build_sort_attributes(resource, params)
        sort_by_name = params['sort_by'].to_s

        if sort_by_name == ''
          if params['sort_by_pin'].to_s != ''
            raise BadRequestSearchError, "Nonsense use of sort_by_pin parameter without corresponding sort_by parameter"
          end
          
          # Default
          return { '_score' => { 'order' => 'desc' } }
        end

        sort_field = sort_by(resource, sort_by_name)
        sort_order = sort_order(params)

        if sort_field.sort == 'field'
          missing_attr = sort_field.date? ? {'missing' => '_last'} : {}
          {
            sort_field.name => { 'order' => sort_order }.merge(missing_attr)
          }
        elsif sort_field.sort == 'script'
          # script sort to work around ElasticSearch not supporting sort by array value fields
          # Could be a potential performance issue.
          raise "Cannot script-sort on analyzed field" if sort_field.analyzed?
          {
            '_script' => {
              'script' => "s='';foreach(val : doc['#{sort_field.name}'].values) {s += val + ' '} s",
              'type' => 'string',
              'order' => sort_order
            }
          }
        elsif sort_field.sort == 'shadow'
          {
            'admin.' + sort_field.name => { 'order' => sort_order }
          }
        elsif sort_field.sort == 'geo_distance'
          if params['sort_by_pin'].to_s == ''
            raise BadRequestSearchError, "Missing required sort_by_pin parameter when sorting on #{sort_field.name}"
          end
          {
            '_geo_distance' => { sort_field.name => params['sort_by_pin'], 'order' => sort_order }
          }
        end
      end

      def self.default_sort_order
        DEFAULT_SORT_ORDER
      end

      def self.valid_sort_orders
        VALID_SORT_ORDERS
      end
    end

  end

end
