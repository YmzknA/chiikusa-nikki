class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!

  def github
    handle_oauth("GitHub")
  end

  def google_oauth2
    handle_oauth("Google")
  end

  def failure
    provider = params[:provider]&.capitalize || "不明なプロバイダー"
    redirect_to root_path, alert: "#{provider}でのログインに失敗しました"
  end

  def handle_oauth(provider_name)
    auth = request.env["omniauth.auth"]

    Rails.logger.info "OmniAuth callback - Provider: #{provider_name}"
    Rails.logger.info "Auth present: #{auth.present?}"
    # セキュリティ: 機密情報（トークン等）を含むauth.to_hashのログ出力を削除
    log_safe_auth_data(auth) if auth.present?

    return handle_invalid_auth(auth) unless valid_oauth_request?(auth)

    handle_valid_oauth(auth, provider_name)
  rescue StandardError => e
    Rails.logger.error "OAuth error: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5)}"
    handle_oauth_error(e, auth)
  end

  def handle_invalid_auth(auth)
    log_oauth_attempt(auth&.provider, auth&.info&.email, false)
    redirect_to root_path, alert: "認証に失敗しました。再度お試しください。"
  end

  def handle_valid_oauth(auth, provider_name)
    if user_signed_in?
      handle_authenticated_user_oauth(auth, provider_name)
    else
      handle_unauthenticated_user_oauth(auth, provider_name)
    end
  end

  def handle_oauth_error(error, auth)
    Rails.logger.error "OAuth authentication error: #{error.message}"
    log_oauth_attempt(auth&.provider, auth&.info&.email, false)

    if user_signed_in?
      redirect_to profile_path, alert: "認証の連携に失敗しました: #{error.message}"
    else
      redirect_to root_path, alert: "認証中にエラーが発生しました。"
    end
  end

  private

  def handle_authenticated_user_oauth(auth, provider_name)
    # ログイン中のユーザーに追加認証を連携
    @user = User.from_omniauth(auth, current_user)

    if @user.persisted?
      log_oauth_attempt(auth.provider, auth.info.email, true)
      # ユーザーは既にログインしているので、プロフィールページにリダイレクト
      redirect_to profile_path, notice: "#{provider_name}アカウントを連携しました。"
    else
      log_oauth_attempt(auth.provider, auth.info.email, false)
      error_msg = @user.errors.full_messages.join(", ")
      redirect_to profile_path, alert: "#{provider_name}アカウントの連携に失敗しました。#{error_msg}"
    end
  end

  def handle_unauthenticated_user_oauth(auth, provider_name)
    # ログアウト状態での通常の認証フロー
    @user = User.from_omniauth(auth)

    if @user.persisted?
      log_oauth_attempt(auth.provider, auth.info.email, true)
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
    else
      log_oauth_attempt(auth.provider, auth.info.email, false)
      error_msg = @user.errors.full_messages.join(", ")
      # Use auth.provider instead of params[:provider] for security
      safe_provider = sanitize_provider_name(auth.provider)
      session["devise.#{safe_provider}_data"] = auth.except(:extra)
      flash[:alert] = "#{provider_name}での認証に失敗しました。#{error_msg}"
      redirect_to root_path
    end
  end

  def sanitize_provider_name(provider)
    # Only allow known OAuth providers
    case provider
    when "github"
      "github"
    when "google_oauth2"
      "google_oauth2"
    else
      "unknown"
    end
  end

  # 安全なOAuthデータのログ出力（機密情報を除外）
  def log_safe_auth_data(auth)
    safe_data = {
      provider: auth.provider,
      uid: auth.uid&.present? ? "[PRESENT]" : "[MISSING]",
      info: {
        email: auth.info&.email&.present? ? "[PRESENT]" : "[MISSING]",
        name: auth.info&.name&.present? ? "[PRESENT]" : "[MISSING]",
        nickname: auth.info&.nickname&.present? ? "[PRESENT]" : "[MISSING]"
      },
      credentials: {
        token: auth.credentials&.token&.present? ? "[PRESENT]" : "[MISSING]",
        expires_at: auth.credentials&.expires_at
      }
    }
    Rails.logger.info "Safe auth data structure: #{safe_data}"
  rescue StandardError => e
    Rails.logger.warn "Failed to log safe auth data: #{e.message}"
  end
end
