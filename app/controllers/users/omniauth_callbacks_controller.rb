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
    
    Rails.logger.debug "OmniAuth callback - Provider: #{provider_name}"
    Rails.logger.debug "Auth present: #{auth.present?}"
    Rails.logger.debug "Auth data: #{auth&.to_hash}"

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
      session["devise.#{params[:provider]}_data"] = auth.except(:extra)
      flash[:alert] = "#{provider_name}での認証に失敗しました。#{error_msg}"
      redirect_to root_path
    end
  end
end
