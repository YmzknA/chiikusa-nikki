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
end
