class GithubSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @repo_exists = check_and_handle_repository_status
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
    
    repo_exists = current_user.verify_github_repository
    
    # リポジトリが存在しない場合、すべての日記のアップロード状態をリセット
    unless repo_exists
      Rails.logger.info "Repository #{current_user.github_repo_name} not found for user #{current_user.id}. Resetting upload status."
      current_user.github_service.reset_all_diaries_upload_status
      flash.now[:alert] = "設定されたGitHubリポジトリが見つかりません。リポジトリが削除された可能性があります。すべての日記のアップロード状態をリセットしました。"
    end
    
    repo_exists
  end
end