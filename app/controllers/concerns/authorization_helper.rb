# frozen_string_literal: true

module AuthorizationHelper
  extend ActiveSupport::Concern

  private

  # 現在のユーザーがリソースの所有者かどうかを確認
  def ensure_resource_owner!(resource, redirect_path = root_path, message = "このリソースにアクセスする権限がありません。")
    return if resource_owner?(resource)

    redirect_to redirect_path, alert: message
  end

  # リソースの所有者かどうかを判定（統一実装）
  def resource_owner?(resource)
    return false unless user_signed_in? && resource.present?

    case resource
    when User
      current_user.id == resource.id
    else
      if resource.respond_to?(:user_id)
        current_user.id == resource.user_id
      elsif resource.respond_to?(:user)
        resource.user == current_user
      else
        false
      end
    end
  end

  # GitHubリポジトリが設定されているかを確認
  def ensure_github_repository_configured!(redirect_path = github_settings_path)
    return if current_user.github_repo_configured?

    redirect_to redirect_path, alert: "GitHubリポジトリの設定が必要です。"
  end
end
