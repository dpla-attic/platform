Contentqa::Engine.routes.draw do
  # All these routes are relative to this engine's mount point defined in the main app

  get "/compare" => "compare#index"
  get "/compare/:id" => "compare#index"
end
