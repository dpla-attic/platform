module CukeApiHelper

  def compute_facets(facets, query_string=nil)
    # Delicately massage query results facets structure into something more testable
    #TODO: Should probably be named compute_facet_counts
    dataset = JSON.parse(load_dataset)
    source = {}
    # for each facet we want to test
    facets.each do |facet|
      (field, subfield) = facet.split('.')

      # NOTE: Only matches ElasticSearch results for not_analyzed fields
      dataset.each do |doc|
        if subfield
          # that regex is a harmless no-op if query_string is nil
          if doc[field]
            if doc[field].is_a?(Hash) && doc[field][subfield].present? && doc.values.any? {|value| value =~ /#{query_string}/}
              facet_value = doc[field][subfield]
              source[facet] ||= {}
              source[facet][facet_value] ||= 0
              source[facet][facet_value] += 1
            elsif doc[field].is_a?(Array) && doc[field].any?
              # need to get values for doc[field].each foo[subfield]
              doc[field].each do |facethash|
                facet_value = facethash[subfield]
                source[facet] ||= {}
                source[facet][facet_value] ||= 0
                source[facet][facet_value] += 1
              end
            end
          end
        else
          if doc[field] && doc.values.any? {|value| value =~ /#{query_string}/}
            source[facet] ||= {}
            source[facet][doc[field]] ||= 0
            source[facet][doc[field]] += 1
          end
        end
      end
    end
    source
  end

  def item_query_to_json(params={})
    item_query(params)['docs']
  end

  def item_fetch(ids_string)
    visit("/api/v1/items/#{ ids_string }")
    JSON.parse(page.source) rescue nil
  end

  def item_query(params={})
    #    format = get_request_format(params)
    visit("/api/v1/items?#{ params.to_param }")
    JSON.parse(page.source) rescue nil
  end

  # def get_request_format(params)
  #   format = params.delete 'format'
  #   format ? '.' + format : ''
  # end

  def load_dataset
    File.read(V1::StandardDataset::ITEMS_JSON_FILE)
  end

  def get_maintenance_file
    File.dirname(__FILE__) + "/../../tmp/maintenance.yml"
  end

  def create_maintenance_file
    system("touch #{get_maintenance_file}")
  end

  def remove_maintenance_file
    system("rm #{get_maintenance_file}")
  end

end

World(CukeApiHelper)
