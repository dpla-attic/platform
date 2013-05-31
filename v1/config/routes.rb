V1::Engine.routes.draw do
  # All these routes are relative to this engine's mount point defined in the main app
  # E.g. if this engine is mounted at "/v1", then 'get "/search"' in this routes.rb
  # would match "/v1/search"

  # Search Items
  #NOTE: We cannot use the defaults->format block until the format field has been renamed in the schema
  #get "/items(.:format)" => "search#items", :as => :items, :defaults => { :format => 'json' }
  get "/items" => "search#items"  #original, WORKS
  #  get "/items(.:format)" => "search#items"  #original + :format, WORKS
  #  get "/items" => "search#items", :as => :items  #original + :format + :as, WORKS

  get "/items/links" => "search#links"
  get "/items(.:format)/*ids" => "search#fetch", :as => :items_fetch  #, :defaults => { :format => 'json' }

  # Search Collections
  get "/collections" => "search#collections"
  get "/collections(.:format)/*ids" => "search#fetch_collections", :as => :collections_fetch

  # API Auth
  # format bit needed to keep parts of the owner email swallowed up as the request format
  post "/api_key(.:format)/*owner" => "api_key#create", :defaults => { :format => 'json' }

  # not fully implemented yet
  #get  "/api_key(.:format)/*owner" => "api_key#show", :defaults => { :format => 'json' }

  # General Utils
  get "/repo/status" => "search#repo_status"

end
