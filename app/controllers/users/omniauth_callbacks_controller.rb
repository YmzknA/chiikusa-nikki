class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :authenticate_user!

  def github
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "GitHub") if is_navigational_format?
    else
      session["devise.github_data"] = request.env["omniauth.auth"].except(:extra)
      flash[:alert] = "認証に失敗しました。"
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path, alert: "GitHubでのログインに失敗しました"
  end
end
