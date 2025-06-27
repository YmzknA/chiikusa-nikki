module GithubRepositoryCreator
  def validate_repository_creation(repo_name)
    return { success: false, message: "リポジトリ名が指定されていません" } if repo_name.blank?
    return { success: false, message: "GitHubクライアントが利用できません" } unless client_available?

    invalid_name_message = "リポジトリ名が無効です。英数字、ハイフン、アンダースコアのみ使用可能です。"
    return { success: false, message: invalid_name_message } unless valid_repository_name?(repo_name)

    nil
  end

  def perform_repository_creation(repo_name)
    Rails.logger.info "Creating repository: #{repo_name} for user: #{@user.username}"

    repository = create_github_repository(repo_name)
    setup_initial_readme(repository, repo_name)

    Rails.logger.info "Repository created successfully: #{repository.full_name}"
    build_success_response(repo_name, repository)
  rescue Octokit::UnprocessableEntity
    handle_repository_exists_error(repo_name)
  rescue Octokit::Unauthorized => e
    handle_unauthorized_error(e)
  rescue Octokit::Forbidden => e
    handle_forbidden_error(e)
  rescue Octokit::Error => e
    handle_github_api_error(e)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  def create_github_repository(repo_name)
    @client.create_repository(repo_name, {
                                private: true,
                                description: "ちいくさ日記 TIL Repository - 毎日の学習記録",
                                auto_init: false,
                                has_issues: false,
                                has_projects: false,
                                has_wiki: false
                              })
  end

  def setup_initial_readme(repository, repo_name)
    readme_content = generate_readme_content(repo_name)
    create_file_result = create_or_update_file(
      repository.full_name,
      "README.md",
      readme_content,
      "Initial commit: Setup TIL repository"
    )

    return if create_file_result[:success]

    Rails.logger.warn "README creation failed, but repository was created: #{repository.full_name}"
  end

  def build_success_response(repo_name, repository)
    {
      success: true,
      message: "リポジトリ「#{repo_name}」を作成しました",
      repository_url: repository.html_url
    }
  end
end
