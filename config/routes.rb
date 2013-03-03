Battlecon::Application.routes.draw do
  resources :games, only: [:show, :update]
end
