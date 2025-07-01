Rails.application.routes.draw do
  # Custom user deletion route (must come before devise_for)
  delete "/users", to: "users#destroy"

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }, skip: [:registrations]

  # OmniAuth failure handling
  match "/users/auth/failure", to: "users/omniauth_callbacks#failure", via: [:get, :post]

  root "home#index"

  # PWA manifest
  get "/manifest.json", to: "application#manifest", defaults: { format: :json }

  resources :diaries, only: [:new, :create, :index, :edit, :update, :show, :destroy] do
    member do
      post :upload_to_github
      get :select_til
      patch :update_til_selection
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

  # チュートリアル
  get "/tutorial", to: "tutorials#show"

  # 静的ページ
  get "/privacy_policy", to: "home#privacy_policy", constraints: { format: :html }
  get "/terms_of_service", to: "home#terms_of_service", constraints: { format: :html }

  # CSP違反レポートエンドポイント
  post "/csp-violation-report", to: "csp_reports#create"
end
