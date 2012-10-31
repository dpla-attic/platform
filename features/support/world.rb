module CukeApiHelper

  def item_query_to_json(params)
    visit("/api/v1/items?#{ params.to_param }")
    JSON.parse(page.source)
  end

end

World(CukeApiHelper)
