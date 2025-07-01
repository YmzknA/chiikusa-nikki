# frozen_string_literal: true

module GithubIntegration
  extend ActiveSupport::Concern

  def upload_to_github
    unless @diary.can_upload_to_github?
      redirect_to diary_path(@diary), alert: "GitHubにアップロードできません。リポジトリ設定とTIL選択を確認してください。"
      return
    end

    result = current_user.github_service.push_til(@diary)
    redirect_path = result[:requires_reauth] ? "/users/auth/github" : diary_path(@diary)
    flash_type = result[:success] ? :notice : :alert

    redirect_to redirect_path, flash_type => result[:message]
  end

  private

  def check_github_repository_status
    return unless current_user.github_repo_configured? && !current_user.verify_github_repository?

    Rails.logger.info "Repository #{current_user.github_repo_name} not found for user #{current_user.id}"
    flash.now[:alert] = "設定されたGitHubリポジトリが見つかりません。GitHub設定を確認してください。"
  end
end
