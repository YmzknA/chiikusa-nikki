class GithubSettingsController < ApplicationController
  include AuthorizationHelper

  before_action :ensure_github_settings_access!

  def show
    @user = current_user
    @repo_exists = check_and_handle_repository_status
    @connection_test_result = test_github_connection if @user.access_token.present?
  end

  def update
    repo_name = params[:github_repo_name]&.strip

    if repo_name.blank?
      redirect_to github_settings_path, alert: "リポジトリ名を入力してください"
      return
    end

    result = current_user.setup_github_repository(repo_name)

    if result[:success]
      redirect_to github_settings_path, notice: result[:message]
    elsif result[:requires_reauth]
      redirect_to "/users/auth/github", alert: result[:message]
    else
      redirect_to github_settings_path, alert: result[:message]
    end
  end

  def destroy
    current_user.reset_github_repository
    redirect_to github_settings_path, notice: "GitHubリポジトリ設定をリセットしました"
  end

  private

  def check_and_handle_repository_status
    return false unless current_user.github_repo_configured?
    return false unless current_user.access_token.present?

    # github_usernameが設定されていない場合は取得を試行
    if current_user.github_username.blank?
      current_user.github_service.fetch_and_update_github_username
      current_user.reload
    end

    repo_exists = current_user.verify_github_repository?

    unless repo_exists
      log_message = "Repository #{current_user.github_repo_name} not found for user #{current_user.id}. " \
                    "Resetting upload status."
      Rails.logger.info log_message
      flash.now[:alert] = "設定されたGitHubリポジトリが見つかりません。リポジトリが削除された可能性があります。すべての日記のアップロード状態をリセットしました。"
    end

    repo_exists
  end

  def test_github_connection
    return nil unless current_user.access_token.present?

    begin
      current_user.github_service.test_github_connection
    rescue StandardError => e
      Rails.logger.error "GitHub connection test failed: #{e.message}"
      { success: false, message: "接続テストでエラーが発生しました" }
    end
  end
end
