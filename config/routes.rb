
Dpla::Application.routes.draw do

  devise_for :users

  root :to => "home#index"

  mount V1::Engine => "/v2"
  mount Contentqa::Engine => "/qa"

end
