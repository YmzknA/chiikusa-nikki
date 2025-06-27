require "octokit"

class GithubService
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
    rescue => e
      Rails.logger.error "Failed to create GitHub client: #{e.message}"
      nil
    end
  end

  def client_available?
    @client.present?
  end

  public

  def create_repository(repo_name)
    return { success: false, message: "リポジトリ名が指定されていません" } if repo_name.blank?
    return { success: false, message: "GitHubクライアントが利用できません" } unless client_available?

    # リポジトリ名のバリデーション（参考実装から）
    unless valid_repository_name?(repo_name)
      return { success: false, message: "リポジトリ名が無効です。英数字、ハイフン、アンダースコアのみ使用可能です。" }
    end

    begin
      # CLAUDE.mdルール準拠: ユーザーが設定する画面でリポジトリ名を入力
      Rails.logger.info "Creating repository: #{repo_name} for user: #{@user.username}"
      
      repository = @client.create_repository(repo_name, {
        private: true,
        description: "Programming Diary TIL Repository - 毎日の学習記録",
        auto_init: false,
        has_issues: false,
        has_projects: false,
        has_wiki: false
      })
      
      # 初期README.mdを作成（参考実装と同様のパターン）
      readme_content = generate_readme_content(repo_name)
      create_file_result = create_or_update_file(
        repository.full_name,
        "README.md",
        readme_content,
        "Initial commit: Setup TIL repository"
      )
      
      unless create_file_result[:success]
        Rails.logger.warn "README creation failed, but repository was created: #{repository.full_name}"
      end
      
      Rails.logger.info "Repository created successfully: #{repository.full_name}"
      { 
        success: true, 
        message: "リポジトリ「#{repo_name}」を作成しました",
        repository_url: repository.html_url 
      }
    rescue Octokit::UnprocessableEntity => e
      Rails.logger.warn "Repository creation failed - already exists: #{repo_name}"
      { success: false, message: "リポジトリ名「#{repo_name}」は既に存在します" }
    rescue Octokit::Unauthorized => e
      Rails.logger.error "GitHub API Unauthorized: #{e.message}"
      { success: false, message: "GitHub認証に失敗しました。再度ログインしてください。" }
    rescue Octokit::Forbidden => e
      Rails.logger.error "GitHub API Forbidden: #{e.message}"
      { success: false, message: "GitHubの権限が不足しています。リポジトリ作成権限を確認してください。" }
    rescue Octokit::Error => e
      Rails.logger.error "GitHub API Error: #{e.class} - #{e.message}"
      log_detailed_error(e)
      { success: false, message: "リポジトリの作成に失敗しました: #{e.message}" }
    rescue => e
      Rails.logger.error "Unexpected error during repository creation: #{e.class} - #{e.message}"
      { success: false, message: "予期しないエラーが発生しました" }
    end
  end

  def repository_exists?(repo_name)
    return false if repo_name.blank?
    return false if @user.access_token.blank?
    
    begin
      repository = @client.repository("#{@user.username}/#{repo_name}")
      Rails.logger.info "Repository verification successful: #{repository.full_name}"
      true
    rescue Octokit::NotFound
      Rails.logger.warn "Repository not found: #{@user.username}/#{repo_name}"
      false
    rescue Octokit::Unauthorized, Octokit::Forbidden => e
      Rails.logger.error "GitHub API access denied: #{e.message}"
      false
    rescue Octokit::Error => e
      Rails.logger.error "GitHub API Error during repository check: #{e.message}"
      false
    end
  end

  def push_til(diary)
    # CLAUDE.mdルール準拠: リポジトリが設定されていない場合はボタンを無効化
    return { success: false, message: "GitHubリポジトリが設定されていません" } if @user.github_repo_name.blank?
    # CLAUDE.mdルール準拠: 既にアップロード済みの場合はボタンを無効化
    return { success: false, message: "すでにGitHubにアップロード済みです" } if diary.github_uploaded?
    return { success: false, message: "GitHubクライアントが利用できません" } unless client_available?

    repo_full_name = "#{@user.username}/#{@user.github_repo_name}"
    # CLAUDE.mdルール準拠: ファイル名は「yymmdd_til」形式
    file_path = "#{diary.date.strftime('%y%m%d')}_til.md"
    content = generate_til_content(diary)
    commit_message = "Add TIL for #{diary.date.strftime('%Y年%m月%d日')}"

    Rails.logger.info "Pushing TIL to GitHub: #{repo_full_name}/#{file_path}"

    # 参考実装のパターンを使用してファイル作成・更新を統一
    result = create_or_update_file(repo_full_name, file_path, content, commit_message)
    
    if result[:success]
      # CLAUDE.mdルール準拠: アップロード後に記録カラムに保存
      diary.update!(github_uploaded: true)
      Rails.logger.info "TIL uploaded successfully: #{repo_full_name}/#{file_path}"
      { 
        success: true, 
        message: "TILをGitHubにアップロードしました",
        file_url: "https://github.com/#{repo_full_name}/blob/main/#{file_path}"
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
      # 既存ファイルの確認
      begin
        existing_file = @client.contents(repo_full_name, path: file_path, ref: branch)
        Rails.logger.debug "File exists, updating: #{file_path}"
        
        # ファイル更新
        @client.update_contents(
          repo_full_name,
          file_path,
          commit_message,
          existing_file.sha,
          content,
          { branch: branch }
        )
        
        { success: true, message: "ファイルを更新しました", action: "updated" }
      rescue Octokit::NotFound
        Rails.logger.debug "File not found, creating: #{file_path}"
        
        # 新規ファイル作成
        @client.create_contents(
          repo_full_name,
          file_path,
          commit_message,
          content,
          { branch: branch }
        )
        
        { success: true, message: "ファイルを作成しました", action: "created" }
      end
    rescue Octokit::NotFound => e
      Rails.logger.error "Repository or branch not found: #{e.message}"
      { success: false, message: "リポジトリまたはブランチが見つかりません。設定を確認してください。" }
    rescue Octokit::Unauthorized => e
      Rails.logger.error "GitHub API Unauthorized: #{e.message}"
      { success: false, message: "GitHub認証に失敗しました。再度ログインしてください。" }
    rescue Octokit::Forbidden => e
      Rails.logger.error "GitHub API Forbidden: #{e.message}"
      { success: false, message: "GitHubの権限が不足しています。リポジトリへのアクセス権限を確認してください。" }
    rescue Octokit::Error => e
      Rails.logger.error "GitHub API Error during file operation: #{e.class} - #{e.message}"
      log_detailed_error(e)
      { success: false, message: "ファイル操作に失敗しました: #{e.message}" }
    rescue => e
      Rails.logger.error "Unexpected error during file operation: #{e.class} - #{e.message}"
      { success: false, message: "予期しないエラーが発生しました" }
    end
  end

  def reset_all_diaries_upload_status
    # CLAUDE.mdルール準拠: リポジトリが無くなった場合は全ての日記のGitHubアップロード記録をfalseにする
    affected_count = @user.diaries.where(github_uploaded: true).count
    @user.diaries.update_all(github_uploaded: false)
    Rails.logger.info "Reset upload status for #{affected_count} diaries for user #{@user.id}"
  end

  def get_repository_info(repo_name)
    return nil if repo_name.blank? || @user.access_token.blank?
    
    begin
      repository = @client.repository("#{@user.username}/#{repo_name}")
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

  private

  def generate_til_content(diary)
    # CLAUDE.mdルール準拠: TIL候補から選択されたものを使用
    selected_til = diary.til_candidates.find_by(index: diary.selected_til_index)
    til_content = selected_til&.content || diary.til_text || diary.notes || "今日も学習に取り組みました。"
    
    # CLAUDE.mdの指示に従い、日付などの基本情報を含める
    <<~MARKDOWN
      # TIL - #{diary.date.strftime('%Y年%m月%d日')}

      ## 今日学んだこと
      #{til_content}

      ## 学習メモ
      #{diary.notes.present? ? diary.notes : "（メモなし）"}

      ## 気分・状態
      #{generate_mood_summary(diary)}

      ---
      *Generated by Programming Diary*  
      *Date: #{diary.date}*  
      *Created: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}*
    MARKDOWN
  end

  def generate_readme_content(repo_name)
    <<~MARKDOWN
      # #{repo_name}

      毎日の学習記録（TIL: Today I Learned）を記録するリポジトリです。

      ## 概要

      このリポジトリは[Programming Diary](https://github.com/programming-diary)で作成された学習記録を自動で保存しています。

      ## ファイル命名規則

      - ファイル名: `yymmdd_til.md`
      - 例: `250627_til.md` (2025年6月27日の記録)

      ## 内容

      各TILファイルには以下の情報が含まれます：

      - その日学んだこと（AI生成候補から選択）
      - 学習メモ
      - 気分・モチベーション・進捗状況
      - 作成日時

      ---
      *This repository is automatically maintained by Programming Diary*
    MARKDOWN
  end

  def generate_mood_summary(diary)
    mood_answers = diary.diary_answers.includes(:question, :answer)
    return "（記録なし）" if mood_answers.empty?
    
    summary_parts = []
    mood_answers.each do |diary_answer|
      question_label = diary_answer.question&.label
      answer_emoji = diary_answer.answer&.emoji
      next unless question_label && answer_emoji
      
      summary_parts << "#{question_label}: #{answer_emoji}"
    end
    
    summary_parts.join(" | ")
  end

  # 参考実装から着想を得た追加のヘルパーメソッド
  def valid_repository_name?(repo_name)
    return false if repo_name.blank?
    
    # GitHubリポジトリ名の基本ルール
    return false if repo_name.length > 100
    return false if repo_name.start_with?('.') || repo_name.end_with?('.')
    return false unless repo_name.match?(/\A[a-zA-Z0-9._-]+\z/)
    
    true
  end

  def log_detailed_error(error)
    return unless error.respond_to?(:response_headers) || error.respond_to?(:response_body)
    
    if error.respond_to?(:response_headers) && error.response_headers
      Rails.logger.error "Response headers: #{error.response_headers}"
    end
    
    if error.respond_to?(:response_body) && error.response_body
      Rails.logger.error "Response body: #{error.response_body}"
    end
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
    rescue => e
      Rails.logger.error "Unexpected error during GitHub connection test: #{e.class} - #{e.message}"
      { success: false, message: "予期しないエラーが発生しました" }
    end
  end
end
