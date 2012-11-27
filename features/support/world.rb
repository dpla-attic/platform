module CukeApiHelper

  def item_query_to_json(params={})
    item_query(params)
    JSON.parse(page.source)['docs']
  end
  
  def item_query(params={})
    visit("/api/v1/items?#{ params.to_param }")
  end

  def load_dataset
    File.read(V1::StandardDataset::ITEMS_JSON_FILE)
  end

  def get_maintenance_file
    File.dirname(__FILE__) + "/../../tmp/maintenance.yml"
  end

end

World(CukeApiHelper)
