Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root "home#index"

  resources :diaries, only: [:new, :create, :index, :edit, :update, :show, :destroy] do
    member do
      post :upload_to_github
    end
    collection do
      post :increment_seed
      post :share_on_x
      get :search_by_date
    end
  end

  # Public diary listing
  get "/public_diaries", to: "diaries#public_index"
  resource :profile, only: [:show, :edit, :update]
  get "/stats", to: "stats#index"

  # ユーザー名設定関連
  get "/setup_username", to: "users#setup_username"
  patch "/setup_username", to: "users#update_username"

  # GitHub設定関連のルート
  get "/github_settings", to: "github_settings#show"
  patch "/github_settings", to: "github_settings#update"
  delete "/github_settings", to: "github_settings#destroy"
end
