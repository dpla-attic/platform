V1::Engine.routes.draw do
  # All these routes are relative to this engine's mount point defined in the main app
  # E.g. if this engine is mounted at "/v2", then 'get "/search"' in this routes.rb
  # would match "/v2/search"

  # JSON-LD context
  get "/items/context" => "search#items_context"
  get "/collections/context" => "search#collections_context"

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
  #get "/api_key(.:format)/*owner" => "api_key#show", :defaults => { :format => 'json' }

  # place-holder for HTTP GET request that should be PUT
  get "/api_key(.:format)/*owner" => "api_key#show_placeholder", :defaults => { :format => 'json' }
  # friendly error message
  get "/api_key" =>  "api_key#index"

  # Monitoring endpoints
  get "/status/repository" => "status#repository", :defaults => { :format => 'json' }
  # get "/status/river" => "status#river", :defaults => { :format => 'json' }
  # get "/status/search_engine" => "status#search_engine", :defaults => { :format => 'json' }
  # get "/status/search_shards" => "status#search_shards", :defaults => { :format => 'json' }
end
