# frozen_string_literal: true

# 個人開発向け基本セキュリティ設定

# 基本的なセッション設定
Rails.application.config.session_store :cookie_store,
                                       key: "_chiikusa_diary_session",
                                       secure: Rails.env.production?,
                                       httponly: true,
                                       same_site: :lax # 個人開発では:strictは厳しすぎるため:laxに変更

# ログから機密情報をフィルタリング（これは重要なので維持）
Rails.application.config.filter_parameters += [
  :password, :access_token, :client_secret,
  :encrypted_access_token, :encrypted_google_access_token,
  :auth, :credentials, :token, :email, :api_key,
  :openai_api_key, :github_token, :refresh_token,
  :secret, :key, :private_key, :certificate
]
