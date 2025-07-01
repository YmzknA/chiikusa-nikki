class ApplicationController < ActionController::Base
  include AuthorizationHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!, except: :manifest
  before_action :restrict_devise_routes
  before_action :check_username_setup, except: :manifest

  def manifest
    render template: "pwa/manifest", content_type: "application/json"
  end

  protected

  def after_sign_in_path_for(_resource)
    return setup_username_path unless current_user.username_configured?

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

  def check_username_setup
    return unless requires_username_setup?

    redirect_to setup_username_path
  end

  def requires_username_setup?
    user_signed_in? &&
      !devise_controller? &&
      !current_user.username_configured? &&
      !username_setup_excluded_action?
  end

  def username_setup_excluded_action?
    controller_name == "users" && action_name.in?(%w[setup_username update_username])
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

  # 個人開発向け基本認可制御（安全な実装）
  def ensure_resource_owner?(resource)
    return true if resource_owned_by_current_user?(resource)

    redirect_to root_path, alert: "アクセス権限がありません。"
    false
  end

  # リソース所有権チェック（ヘルパーメソッド）
  def resource_owned_by_current_user?(resource)
    return false unless user_signed_in? && resource.present?

    case resource
    when User
      current_user.id == resource.id
    else
      resource.respond_to?(:user_id) && current_user.id == resource.user_id
    end
  end
end
