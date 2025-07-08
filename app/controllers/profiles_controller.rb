class ProfilesController < ApplicationController
  include AuthorizationHelper

  before_action :authenticate_user!

  def show; end

  def edit; end

  def update
    # アバター更新時の追加検証
    if user_params[:avatar].present?
      unless avatar_update_allowed?
        return render :edit, alert: I18n.t('avatar_security.update_permission_denied'), status: :forbidden
      end
    end

    if current_user.update(user_params)
      redirect_to profile_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :avatar)
  end

  def avatar_update_allowed?
    account_age_limit = Rails.application.config.avatar_update_account_age_limit || 1.day
    update_interval_limit = Rails.application.config.avatar_update_interval_limit || 1.hour
    
    # アカウント作成から指定時間経過チェック
    current_user.created_at < account_age_limit.ago &&
    # 短時間での連続更新防止
    (current_user.updated_at.nil? || current_user.updated_at < update_interval_limit.ago)
  end
end