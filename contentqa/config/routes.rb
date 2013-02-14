Contentqa::Engine.routes.draw do
  get "search/index"

  # All these routes are relative to this engine's mount point defined in the main app

  get "/" => "search#index"
  get "/compare" => "compare#index"
  #the * wildcard prevents Rails from splitting IDs on forward slashes, which is its default

  get "/compare(.:format)/*ids" => "compare#index"  #, :as => :compare_what
  get "/search" => "search#index"
end
