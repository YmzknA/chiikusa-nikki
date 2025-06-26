Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root "home#index"

  resources :diaries, only: [:new, :create, :index, :edit, :update, :show]
  resource :profile, only: [:show, :edit, :update]
  get "/stats", to: "stats#index"
end
