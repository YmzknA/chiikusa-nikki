class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_username_set, only: [:setup_username, :update_username]

  def setup_username
    # ユーザー名が未設定の場合のみアクセス可能
  end

  def update_username
    if current_user.update(username_params)
      redirect_to diaries_path, notice: "ユーザー名を設定しました！日記を書いてみましょう 📝"
    else
      render :setup_username, status: :unprocessable_entity
    end
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
