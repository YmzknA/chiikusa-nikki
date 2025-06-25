Rails.application.routes.draw do
  root "home#index"

  get "/auth/github/callback", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :diaries, only: [:new, :create, :index, :edit, :update, :show]
  resource :profile, only: [:show, :edit, :update]
  get "/stats", to: "stats#index"
end
