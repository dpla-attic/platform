Dpla::Application.routes.draw do

  devise_for :users

  root :to => redirect('http://dp.la/info/developers/codex/')

  mount V1::Engine => "/v2"
  mount Contentqa::Engine => "/qa"

end
