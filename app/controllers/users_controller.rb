class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_username_set, only: [:setup_username, :update_username]

  def setup_username
    # ユーザー名が未設定の場合のみアクセス可能
  end

  def update_username
    if current_user.update(username_params)
      redirect_to tutorial_path, notice: "ユーザー名を設定しました！まずは使い方を確認しましょう 🌱"
    else
      render :setup_username, status: :unprocessable_entity
    end
  end

  def destroy
    user = current_user
    username = user.username
    
    # ユーザーとその関連データを削除
    if user.destroy
      # セッションをクリア
      sign_out(user)
      redirect_to root_path, notice: "#{username}さんのアカウントを削除しました。ご利用ありがとうございました。"
    else
      Rails.logger.error "User deletion failed: #{user.errors.full_messages.join(', ')}"
      redirect_to profile_path, alert: "アカウントの削除に失敗しました。時間をおいて再度お試しください。"
    end
  rescue StandardError => e
    Rails.logger.error "User deletion failed: #{e.message}"
    redirect_to profile_path, alert: "アカウントの削除に失敗しました。時間をおいて再度お試しください。"
  end

  private

  def username_params
    params.require(:user).permit(:username)
  end

  def redirect_if_username_set
    return unless current_user.username_configured?

    redirect_to diaries_path
  end
end
