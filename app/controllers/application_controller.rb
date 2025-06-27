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
end
