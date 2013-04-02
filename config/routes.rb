Battlecon::Application.routes.draw do
  get '/' => 'home#landing', as: 'landing'

  get "/register" => 'sessions#select_username', as: 'select_username'
  post "/register" => 'sessions#register_username', as: 'register'

  post "sessions/login", as: "login"
  post "sessions/logout", as: "logout"

  get '/games/challenge', :as => 'challenge'
  get '/games/required_input_count', :as => 'required_input_count'
  resources :games, only: [:show, :update, :index]
  resources :users, only: [:show, :update]
  resources :challenges

  if Rails.env.development?
    get '/login' => 'sessions#dev_login'
  end
end
