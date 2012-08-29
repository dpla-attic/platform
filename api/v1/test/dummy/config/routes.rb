Rails.application.routes.draw do

  mount V1::Engine => "/v1"
end
