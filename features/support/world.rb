module CukeApiHelper

  def compute_facets(facets, query_string=nil)
    # Delicately massage query results facets structure into something more testable
    dataset = JSON.parse(load_dataset)
    source = {}
    # for each facet they want to test
    facets.each do |facet|
      (field, subfield) = facet.split('.')

      # NOTE: Only matches ElasticSearch results for not_analyzed fields
      dataset.each do |doc|
        if subfield
          # that regex is a harmless no-op if query_string is nil
          if doc[field] && doc[field][subfield].present? && doc.values.any? {|value| value =~ /#{query_string}/}
            source[facet] ||= {}
            source[facet][doc[field][subfield]] ||= 0
            source[facet][doc[field][subfield]] += 1
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
  
  def item_query(params={})
    visit("/api/v1/items?#{ params.to_param }")
    JSON.parse(page.source) rescue nil
  end

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
