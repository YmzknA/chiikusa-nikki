class ProfilesController < ApplicationController
  include AuthorizationHelper

  before_action :authenticate_user!

  def show; end

  def edit; end

  def update
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
end
