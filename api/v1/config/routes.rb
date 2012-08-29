V1::Engine.routes.draw do
  # All these routes are relative to this engine's mount point defined in the main app

  get "/search" => "search#index", :as => "search"

end
