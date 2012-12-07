
Dpla::Application.routes.draw do

  devise_for :users

  root :to => "home#index"

  mount V1::Engine => "/api/v1"
  mount Contentqa::Engine => "/qa"

end
