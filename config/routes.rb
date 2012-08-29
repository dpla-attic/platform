
Dpla::Application.routes.draw do

  root :to => "home#index"

  mount V1::Engine => "/api/v1" #, :as => "v1_api"

end
