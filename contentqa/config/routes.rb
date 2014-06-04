Contentqa::Engine.routes.draw do
  # All these routes are relative to this engine's mount point defined in the main app

  get "/" => "search#index"
  get "/search" => "search#index"
  get "/compare" => "compare#index"
  #the * wildcard prevents Rails from splitting IDs on forward slashes, which is its default
  get "/compare(.:format)/*ids" => "compare#index"
  get "/reporting" => "reporting#index"
  get "/reporting/provider" => "reporting#provider"
  get "/reporting/create" => "reporting#create"
  get "/reporting/download" => "reporting#download"
  get "/reporting/errors" => "reporting#errors"
  get "/reporting/global" => "reporting#global"
end
