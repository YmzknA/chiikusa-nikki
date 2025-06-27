class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :restrict_devise_routes

  protected

  def after_sign_in_path_for(_resource)
    diaries_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  def unauthenticated_user
    redirect_to root_path, alert: "ログインが必要です"
  end

  private

  def restrict_devise_routes
    if devise_controller? && action_name.in?(%w[new create]) && controller_name.in?(%w[sessions registrations])
      redirect_to root_path, alert: "この機能は利用できません"
    end
  end

  # セキュリティヘルパーメソッド
  def log_oauth_attempt(provider, email, success)
    user_info = user_signed_in? ? "logged_in_user_id=#{current_user.id}" : "anonymous"
    log_oauth_details(provider, email, success, user_info)
  end

  def log_oauth_details(provider, email, success, user_info)
    email_info = email&.presence || "N/A"
    Rails.logger.info("OAuth attempt: provider=#{provider}, email=#{email_info}, " \
                      "success=#{success}, #{user_info}, ip=#{request.remote_ip}, " \
                      "user_agent=#{request.user_agent}")
  end

  def valid_oauth_request?(auth)
    return false unless basic_oauth_valid?(auth)
    return false unless valid_email_format?(auth.info.email)

    # ログイン中の場合の追加チェック
    return true unless user_signed_in?

    validate_provider_connection?(auth.provider)
  end

  def basic_oauth_valid?(auth)
    auth.present? &&
      auth.provider.in?(%w[github google_oauth2]) &&
      auth.info&.email.present? &&
      auth.uid.present?
  end

  def valid_email_format?(email)
    email.match?(/\A[^@\s]+@[^@\s]+\z/)
  end

  def validate_provider_connection?(provider)
    case provider
    when "github"
      validate_github_connection?
    when "google_oauth2"
      validate_google_connection?
    else
      true
    end
  end

  def validate_github_connection?
    return true unless current_user.github_connected?

    Rails.logger.warn "User #{current_user.id} attempted to link GitHub but already connected"
    false
  end

  def validate_google_connection?
    return true unless current_user.google_connected?

    Rails.logger.warn "User #{current_user.id} attempted to link Google but already connected"
    false
  end
end
