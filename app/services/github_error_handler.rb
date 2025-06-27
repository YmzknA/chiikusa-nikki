module GithubErrorHandler
  def handle_repository_exists_error(repo_name)
    Rails.logger.warn "Repository creation failed - already exists: #{repo_name}"
    { success: false, message: "リポジトリ名「#{repo_name}」は既に存在します" }
  end

  def handle_unauthorized_error(error)
    Rails.logger.error "GitHub API Unauthorized: #{error.message}"

    # Clear invalid token and related data
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

  def handle_rate_limit_error(error)
    reset_time = extract_rate_limit_reset_time(error)
    wait_time = calculate_wait_time(reset_time)

    Rails.logger.warn "GitHub API rate limit exceeded. Reset at: #{reset_time}"

    {
      success: false,
      message: "GitHub API制限に達しました。#{format_wait_time(wait_time)}後に再試行してください。",
      retry_after: wait_time,
      rate_limited: true
    }
  end

  private

  def extract_rate_limit_reset_time(error)
    return nil unless error.respond_to?(:response_headers)

    reset_header = error.response_headers["X-RateLimit-Reset"] ||
                   error.response_headers["x-ratelimit-reset"]
    return nil unless reset_header

    Time.at(reset_header.to_i)
  rescue StandardError
    nil
  end

  def calculate_wait_time(reset_time)
    return 60 unless reset_time # Default 1 minute if no reset time

    wait_seconds = (reset_time - Time.current).to_i
    [wait_seconds, 0].max
  end

  def format_wait_time(seconds)
    if seconds < 60
      "#{seconds}秒"
    elsif seconds < 3600
      minutes = (seconds / 60).round
      "約#{minutes}分"
    else
      hours = (seconds / 3600).round
      "約#{hours}時間"
    end
  end

  def valid_repository_name?(repo_name)
    return false if repo_name.blank?

    # GitHub repository name validation rules
    return false if repo_name.length > 100
    return false if repo_name.start_with?(".", "-") || repo_name.end_with?(".", "-")
    return false unless repo_name.match?(/\A[a-zA-Z0-9._-]+\z/)
    return false if repo_name.include?("..")

    # Reserved Windows names (case-insensitive)
    reserved_names = %w[con prn aux nul com1 com2 com3 com4 com5 com6 com7 com8 com9
                        lpt1 lpt2 lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9]
    return false if reserved_names.include?(repo_name.downcase)

    # Common problematic names
    problematic_names = %w[. .. git HEAD]
    return false if problematic_names.include?(repo_name)

    true
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
