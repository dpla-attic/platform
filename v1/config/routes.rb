V1::Engine.routes.draw do
  # All these routes are relative to this engine's mount point defined in the main app
  # E.g. if this engine is mounted at "/api/v1", then 'get "/search"' in this routes.rb
  # would match "/api/v1/search"

  get "/items" => "search#items"
  get "/items/links" => "search#links"
  get "/items/*ids" => "search#fetch"

end
