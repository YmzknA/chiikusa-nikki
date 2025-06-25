Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "diaries#index"

  get "/auth/github/callback", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :diaries, only: [:new, :create, :index]
  resource :profile, only: [:show, :edit, :update]
  get "/stats", to: "stats#index"
end
