Rails.application.routes.draw do
  root :to => "home#index"
  mount V1::Engine => "/v1"
end
