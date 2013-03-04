Battlecon::Application.routes.draw do
  get '/' => 'home#landing', as: 'landing'
  post "sessions/login", as: "login"
  post "sessions/logout", as: "logout"
  get '/games/challenge', :as => 'challenge'
  resources :games, only: [:show, :update, :index]
end
