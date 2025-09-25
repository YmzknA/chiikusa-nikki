require "octokit"

class GithubService
  include GithubFileOperations
  include GithubContentGenerator
  include GithubRepositoryCreator
  include GithubErrorHandler
  attr_reader :user, :client

  def initialize(user)
    @user = user
    @client = create_github_client
  end

  private

  def create_github_client
    return nil if @user.access_token.blank?

    begin
      Octokit::Client.new(
        access_token: @user.access_token,
        auto_paginate: true,
        per_page: 100
      )
    rescue StandardError => e
      Rails.logger.error "Failed to create GitHub client: #{e.message}"
      nil
    end
  end

  def client_available?
    @client.present?
  end

  public

  def create_repository(repo_name)
    validation_result = validate_repository_creation(repo_name)
    return validation_result unless validation_result.nil?

    perform_repository_creation(repo_name)
  end

  def repository_exists?(repo_name)
    return false if repo_name.blank?
    return false if @user.access_token.blank?
    return false if @user.github_username.blank?

    begin
      repository = @client.repository("#{@user.github_username}/#{repo_name}")
      Rails.logger.info "Repository verification successful: #{repository.full_name}"
      true
    rescue Octokit::NotFound
      Rails.logger.warn "Repository not found: #{@user.github_username}/#{repo_name}"
      false
    rescue Octokit::Unauthorized, Octokit::Forbidden => e
      Rails.logger.warn "GitHub API access denied: #{e.message}"
      false
    rescue Octokit::Error => e
      Rails.logger.warn "GitHub API Error during repository check: #{e.message}"
      false
    end
  end

  def push_til(diary)
    # リポジトリが設定されていない場合はボタンを無効化
    return { success: false, message: "GitHubリポジトリが設定されていません" } if @user.github_repo_name.blank?
    # 既にアップロード済みの場合はボタンを無効化
    return { success: false, message: "すでにGitHubにアップロード済みです" } if diary.github_uploaded?
    return { success: false, message: "GitHubクライアントが利用できません" } unless client_available?
    return { success: false, message: "GitHubユーザー名が取得できません" } if @user.github_username.blank?

    repo_full_name = "#{@user.github_username}/#{@user.github_repo_name}"
    # ファイル名は「yymmdd_til」形式
    file_path = "#{diary.date.strftime('%y%m%d')}_til.md"
    content = generate_til_content(diary)
    commit_message = "Add TIL for #{diary.date.strftime('%Y年%m月%d日')}"

    Rails.logger.info "Pushing TIL to GitHub: #{repo_full_name}/#{file_path}"

    # 参考実装のパターンを使用してファイル作成・更新を統一
    result = create_or_update_file(repo_full_name, file_path, content, commit_message)

    if result[:success]
      file_url = "https://github.com/#{repo_full_name}/blob/main/#{file_path}"
      # アップロード後に記録カラムに保存
      audit_data = {
        github_uploaded: true,
        github_uploaded_at: Time.current,
        github_file_path: file_path,
        github_repository_url: "https://github.com/#{repo_full_name}"
      }

      # Add commit SHA if available in result
      audit_data[:github_commit_sha] = result[:commit_sha] if result[:commit_sha]

      diary.update!(audit_data)
      Rails.logger.info "TIL uploaded successfully: #{repo_full_name}/#{file_path}"
      {
        success: true,
        message: "TILをGitHubにアップロードしました",
        file_url: file_url
      }
    else
      Rails.logger.error "TIL upload failed: #{result[:message]}"
      result
    end
  end

  # 参考実装から着想を得た統一ファイル操作メソッド
  def create_or_update_file(repo_full_name, file_path, content, commit_message, branch = "main")
    return { success: false, message: "GitHubクライアントが利用できません" } unless client_available?

    begin
      handle_file_operation(repo_full_name, file_path, content, commit_message, branch)
    rescue Octokit::NotFound => e
      handle_repository_not_found_error(e)
    rescue Octokit::Unauthorized => e
      handle_file_unauthorized_error(e)
    rescue Octokit::Forbidden => e
      handle_file_forbidden_error(e)
    rescue Octokit::Error => e
      handle_file_api_error(e)
    rescue StandardError => e
      handle_file_unexpected_error(e)
    end
  end

  def reset_all_diaries_upload_status
    # リポジトリが無くなった場合は全ての日記のGitHubアップロード記録をfalseにする
    affected_count = @user.diaries.where(github_uploaded: true).count
    @user.diaries.update_all(
      github_uploaded: false,
      github_uploaded_at: nil,
      github_file_path: nil,
      github_commit_sha: nil,
      github_repository_url: nil
    )
    Rails.logger.info "Reset upload status and audit data for #{affected_count} diaries for user #{@user.id}"
  end

  def get_repository_info(repo_name)
    return nil if repo_name.blank? || @user.access_token.blank? || @user.github_username.blank?

    begin
      repository = @client.repository("#{@user.github_username}/#{repo_name}")
      {
        name: repository.name,
        full_name: repository.full_name,
        private: repository.private,
        description: repository.description,
        created_at: repository.created_at,
        updated_at: repository.updated_at,
        url: repository.html_url
      }
    rescue Octokit::Error => e
      Rails.logger.error "Failed to get repository info: #{e.message}"
      nil
    end
  end

  def fetch_and_update_github_username
    return false unless client_available?

    begin
      github_user = @client.user
      @user.update!(github_username: github_user.login)
      Rails.logger.info "Updated github_username for user #{@user.id}: #{github_user.login}"
      true
    rescue Octokit::Error => e
      Rails.logger.error "Failed to fetch GitHub username: #{e.message}"
      false
    rescue StandardError => e
      Rails.logger.error "Unexpected error while fetching GitHub username: #{e.message}"
      false
    end
  end

  def test_github_connection
    return { success: false, message: "GitHubクライアントが利用できません" } unless client_available?

    begin
      github_user = @client.user
      {
        success: true,
        message: "GitHub接続成功",
        username: github_user.login,
        email: github_user.email
      }
    rescue Octokit::Unauthorized
      { success: false, message: "GitHub認証が無効です。再認証が必要です。" }
    rescue Octokit::Forbidden
      { success: false, message: "GitHub APIへのアクセスが制限されています。" }
    rescue Octokit::Error => e
      { success: false, message: "GitHub API エラー: #{e.message}" }
    rescue StandardError => e
      { success: false, message: "予期しないエラーが発生しました: #{e.message}" }
    end
  end
end
