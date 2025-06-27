Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root "home#index"

  resources :diaries, only: [:new, :create, :index, :edit, :update, :show, :destroy] do
    member do
      post :upload_to_github
    end
  end
  resource :profile, only: [:show, :edit, :update]
  get "/stats", to: "stats#index"

  # GitHub設定関連のルート
  get "/github_settings", to: "github_settings#show"
  patch "/github_settings", to: "github_settings#update"
  delete "/github_settings", to: "github_settings#destroy"
end
