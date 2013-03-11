Battlecon::Application.routes.draw do
  get '/' => 'home#landing', as: 'landing'
  post "sessions/login", as: "login"
  post "sessions/logout", as: "logout"
  get '/games/challenge', :as => 'challenge'
  get '/games/required_input_count', :as => 'required_input_count'
  resources :games, only: [:show, :update, :index]
  resources :users, only: [:show, :update]

  if Rails.env.development?
    get '/login' => 'sessions#dev_login'
  end
end
