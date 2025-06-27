module GithubFileOperations
  def handle_file_operation(repo_full_name, file_path, content, commit_message, branch)
    # 既存ファイルの確認
    existing_file = @client.contents(repo_full_name, path: file_path, ref: branch)
    Rails.logger.debug "File exists, updating: #{file_path}"
    update_existing_file(repo_full_name, file_path, content, commit_message, existing_file)
  rescue Octokit::NotFound
    Rails.logger.debug "File not found, creating: #{file_path}"
    create_new_file(repo_full_name, file_path, content, commit_message)
  end

  def update_existing_file(repo_full_name, file_path, content, commit_message, existing_file)
    @client.update_contents(
      repo_full_name,
      file_path,
      commit_message,
      existing_file.sha,
      content,
      { branch: "main" }
    )
    { success: true, message: "ファイルを更新しました", action: "updated" }
  end

  def create_new_file(repo_full_name, file_path, content, commit_message)
    @client.create_contents(
      repo_full_name,
      file_path,
      commit_message,
      content,
      { branch: "main" }
    )
    { success: true, message: "ファイルを作成しました", action: "created" }
  end

  def handle_repository_not_found_error(error)
    Rails.logger.error "Repository or branch not found: #{error.message}"
    { success: false, message: "リポジトリまたはブランチが見つかりません。設定を確認してください。" }
  end

  def handle_file_unauthorized_error(error)
    Rails.logger.error "GitHub API Unauthorized: #{error.message}"

    {
      success: false,
      message: "GitHub認証が期限切れです。再度ログインしてください。",
      requires_reauth: true
    }
  end

  def handle_file_forbidden_error(error)
    Rails.logger.error "GitHub API Forbidden: #{error.message}"
    { success: false, message: "GitHubの権限が不足しています。リポジトリへのアクセス権限を確認してください。" }
  end

  def handle_file_api_error(error)
    # Handle rate limiting specifically for file operations
    return handle_rate_limit_error(error) if error.is_a?(Octokit::TooManyRequests)

    Rails.logger.error "GitHub API Error during file operation: #{error.class} - #{error.message}"
    log_detailed_error(error)
    { success: false, message: "ファイル操作に失敗しました。しばらく時間をおいて再試行してください。" }
  end

  def handle_file_unexpected_error(error)
    Rails.logger.error "Unexpected error during file operation: #{error.class} - #{error.message}"
    { success: false, message: "予期しないエラーが発生しました" }
  end
end
