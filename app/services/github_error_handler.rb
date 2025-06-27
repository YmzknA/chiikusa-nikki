module GithubErrorHandler
  include GithubRateLimitHandler
  include GithubRepositoryValidator
  def handle_repository_exists_error(repo_name)
    Rails.logger.warn "Repository creation failed - already exists: #{repo_name}"
    { success: false, message: "リポジトリ名「#{repo_name}」は既に存在します" }
  end

  def handle_unauthorized_error(error)
    Rails.logger.error "GitHub API Unauthorized: #{error.message}"

    # Clear invalid token
    if @user
      @user.reset_github_access
      Rails.logger.info "Cleared invalid GitHub token for user #{@user.id}"
    end

    {
      success: false,
      message: "GitHub認証が期限切れです。再度ログインしてください。",
      requires_reauth: true
    }
  end

  def handle_forbidden_error(error)
    Rails.logger.error "GitHub API Forbidden: #{error.message}"
    { success: false, message: "GitHubの権限が不足しています。リポジトリ作成権限を確認してください。" }
  end

  def handle_github_api_error(error)
    # Handle rate limiting specifically
    return handle_rate_limit_error(error) if error.is_a?(Octokit::TooManyRequests)

    Rails.logger.error "GitHub API Error: #{error.class} - #{error.message}"
    log_detailed_error(error)
    { success: false, message: "GitHubの操作に失敗しました。しばらく時間をおいて再試行してください。" }
  end

  def handle_unexpected_error(error)
    Rails.logger.error "Unexpected error during repository creation: #{error.class} - #{error.message}"
    { success: false, message: "予期しないエラーが発生しました" }
  end

  def log_detailed_error(error)
    return unless error.respond_to?(:response_headers) || error.respond_to?(:response_body)

    if error.respond_to?(:response_headers) && error.response_headers
      Rails.logger.error "Response headers: #{error.response_headers}"
    end

    return unless error.respond_to?(:response_body) && error.response_body

    Rails.logger.error "Response body: #{error.response_body}"
  end

  def test_github_connection
    return { success: false, message: "GitHubクライアントが利用できません" } unless client_available?

    begin
      user_info = @client.user
      Rails.logger.info "GitHub connection test successful for user: #{user_info.login}"
      {
        success: true,
        message: "GitHub接続テスト成功",
        user_info: {
          login: user_info.login,
          name: user_info.name,
          public_repos: user_info.public_repos,
          private_repos: user_info.total_private_repos
        }
      }
    rescue Octokit::Unauthorized => e
      Rails.logger.error "GitHub connection test failed - Unauthorized: #{e.message}"
      { success: false, message: "GitHub認証に失敗しました。アクセストークンを確認してください。" }
    rescue Octokit::Forbidden => e
      Rails.logger.error "GitHub connection test failed - Forbidden: #{e.message}"
      { success: false, message: "GitHubの権限が不足しています。" }
    rescue Octokit::Error => e
      Rails.logger.error "GitHub connection test failed: #{e.class} - #{e.message}"
      { success: false, message: "GitHub接続テストに失敗しました: #{e.message}" }
    rescue StandardError => e
      Rails.logger.error "Unexpected error during GitHub connection test: #{e.class} - #{e.message}"
      { success: false, message: "予期しないエラーが発生しました" }
    end
  end
end
