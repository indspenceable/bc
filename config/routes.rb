Battlecon::Application.routes.draw do
  get '/' => 'home#landing', as: 'landing'
  post "sessions/login", as: "login"
  post "sessions/logout", as: "logout"
  resources :games, only: [:show, :update]
end
