Battlecon::Application.routes.draw do
  post "sessions/login", as: "login"
  post "sessions/logout", as: "logout"
  resources :games, only: [:show, :update]
end
