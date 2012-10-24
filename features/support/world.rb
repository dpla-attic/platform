module CukeApiHelper

  def item_query_to_json(params)
    puts "item_query_to_json: #{params.inspect}"
    visit("/api/v1/items?#{ params.to_param }")
    JSON.parse(page.source)
  end

end

World(CukeApiHelper)
