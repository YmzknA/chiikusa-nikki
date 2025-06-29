require "rails_helper"

RSpec.describe "GitHub Integration", type: :system do
  let(:user) { create(:user, :with_github) }
  let(:diary) { create(:diary, :with_selected_til, user: user) }
  let(:mock_github_service) { instance_double(GithubService) }

  before do
    sign_in user
    allow(user).to receive(:github_service).and_return(mock_github_service)
  end

  describe "GitHub settings management", js: true do
    it "allows user to configure GitHub repository" do
      allow(mock_github_service).to receive(:create_repository)
        .and_return({ success: true, message: "リポジトリを作成しました" })
      allow(mock_github_service).to receive(:repository_exists?).and_return(true)
      allow(mock_github_service).to receive(:test_github_connection)
        .and_return({ success: true, message: "接続成功" })

      visit github_settings_path

      expect(page).to have_content("GitHub設定")

      fill_in "github_repo_name", with: "my-til-repo"
      click_button "リポジトリを作成"

      expect(page).to have_content("リポジトリを作成しました")
    end

    it "shows error when repository creation fails" do
      allow(mock_github_service).to receive(:create_repository)
        .and_return({ success: false, message: "リポジトリの作成に失敗しました" })

      visit github_settings_path

      fill_in "github_repo_name", with: "invalid-repo"
      click_button "リポジトリを作成"

      expect(page).to have_content("リポジトリの作成に失敗しました")
    end

    it "allows user to reset GitHub configuration" do
      user.update!(github_repo_name: "existing-repo")

      visit github_settings_path

      expect(page).to have_content("existing-repo")

      click_button "設定をリセット"

      expect(page).to have_content("リセットしました")
    end

    it "shows connection status" do
      user.update!(github_repo_name: "test-repo")
      allow(mock_github_service).to receive(:repository_exists?).and_return(true)
      allow(mock_github_service).to receive(:test_github_connection)
        .and_return({ success: true, message: "接続成功" })

      visit github_settings_path

      expect(page).to have_content("接続状態")
    end

    it "handles missing repository gracefully" do
      user.update!(github_repo_name: "missing-repo")
      allow(mock_github_service).to receive(:repository_exists?).and_return(false)

      visit github_settings_path

      expect(page).to have_content("見つかりません")
    end
  end

  describe "TIL upload functionality", js: true do
    before do
      user.update!(github_repo_name: "test-til")
    end

    it "allows uploading TIL to GitHub" do
      allow(mock_github_service).to receive(:push_til)
        .and_return({ success: true, message: "TILをGitHubにアップロードしました" })

      visit diary_path(diary)

      expect(page).to have_button("GitHubにアップロード")

      click_button "GitHubにアップロード"

      expect(page).to have_content("アップロードしました")
    end

    it "shows error when upload fails" do
      allow(mock_github_service).to receive(:push_til)
        .and_return({ success: false, message: "アップロードに失敗しました" })

      visit diary_path(diary)

      click_button "GitHubにアップロード"

      expect(page).to have_content("アップロードに失敗しました")
    end

    it "disables upload button when already uploaded" do
      diary.update!(github_uploaded: true)

      visit diary_path(diary)

      expect(page).to have_button("GitHubにアップロード", disabled: true)
    end

    it "hides upload button when repository not configured" do
      user.update!(github_repo_name: nil)

      visit diary_path(diary)

      expect(page).not_to have_button("GitHubにアップロード")
    end

    it "handles authentication errors during upload" do
      allow(mock_github_service).to receive(:push_til)
        .and_return({ 
          success: false, 
          requires_reauth: true, 
          message: "認証が必要です" 
        })

      visit diary_path(diary)

      click_button "GitHubにアップロード"

      expect(page).to have_current_path("/users/auth/github")
    end
  end

  describe "upload status indicators", js: true do
    before do
      user.update!(github_repo_name: "test-til")
    end

    it "shows upload status on diary list" do
      uploaded_diary = create(:diary, :github_uploaded, user: user)
      unuploaded_diary = create(:diary, :with_selected_til, user: user)

      visit diaries_path

      expect(page).to have_content("アップロード済み")
      expect(page).to have_content("未アップロード")
    end

    it "shows upload timestamp" do
      diary.update!(
        github_uploaded: true,
        github_uploaded_at: Time.current,
        github_file_path: "250629_til.md"
      )

      visit diary_path(diary)

      expect(page).to have_content("GitHubにアップロード済み")
      expect(page).to have_content(diary.github_uploaded_at.strftime("%Y年%m月%d日"))
    end

    it "shows GitHub file link when uploaded" do
      diary.update!(
        github_uploaded: true,
        github_repository_url: "https://github.com/testuser/test-til",
        github_file_path: "250629_til.md"
      )

      visit diary_path(diary)

      expect(page).to have_link("GitHubで表示", 
        href: "https://github.com/testuser/test-til/blob/main/250629_til.md")
    end
  end

  describe "bulk operations", js: true do
    let!(:diaries) { create_list(:diary, 3, :github_uploaded, user: user) }

    before do
      user.update!(github_repo_name: "test-til")
    end

    it "resets all upload statuses when repository is reset" do
      visit github_settings_path

      click_button "設定をリセット"

      expect(page).to have_content("リセットしました")

      # Verify all diaries are marked as not uploaded
      diaries.each do |diary|
        expect(diary.reload.github_uploaded).to be false
      end
    end

    it "shows upload statistics" do
      visit github_settings_path

      expect(page).to have_content("アップロード済み日記数")
      expect(page).to have_content("3")
    end
  end

  describe "repository validation", js: true do
    it "validates repository name format" do
      visit github_settings_path

      fill_in "github_repo_name", with: ""
      click_button "リポジトリを作成"

      expect(page).to have_content("入力してください")
    end

    it "handles special characters in repository name" do
      visit github_settings_path

      fill_in "github_repo_name", with: "invalid@repo"
      click_button "リポジトリを作成"

      expect(page).to have_content("無効な文字")
    end

    it "checks for existing repositories" do
      allow(mock_github_service).to receive(:create_repository)
        .and_return({ success: false, message: "既に存在します" })

      visit github_settings_path

      fill_in "github_repo_name", with: "existing-repo"
      click_button "リポジトリを作成"

      expect(page).to have_content("既に存在します")
    end
  end

  describe "GitHub connection status", js: true do
    it "shows connection test results" do
      allow(mock_github_service).to receive(:test_github_connection)
        .and_return({ 
          success: true, 
          message: "接続成功",
          user_info: { login: "testuser", public_repos: 5 }
        })

      visit github_settings_path

      expect(page).to have_content("接続成功")
    end

    it "handles connection failures" do
      allow(mock_github_service).to receive(:test_github_connection)
        .and_return({ success: false, message: "認証エラー" })

      visit github_settings_path

      expect(page).to have_content("認証エラー")
    end

    it "shows GitHub user information" do
      allow(mock_github_service).to receive(:test_github_connection)
        .and_return({ 
          success: true,
          user_info: {
            login: "testuser",
            name: "Test User",
            public_repos: 10,
            total_private_repos: 5
          }
        })

      visit github_settings_path

      expect(page).to have_content("testuser")
      expect(page).to have_content("10")
    end
  end

  describe "error recovery", js: true do
    it "handles network timeouts gracefully" do
      allow(mock_github_service).to receive(:push_til)
        .and_raise(Net::TimeoutError)

      visit diary_path(diary)

      click_button "GitHubにアップロード"

      expect(page).to have_content("タイムアウト")
    end

    it "handles rate limiting" do
      allow(mock_github_service).to receive(:push_til)
        .and_return({ 
          success: false, 
          message: "API制限に達しました。しばらく待ってから再試行してください。" 
        })

      visit diary_path(diary)

      click_button "GitHubにアップロード"

      expect(page).to have_content("API制限")
    end

    it "provides retry options for failed uploads" do
      allow(mock_github_service).to receive(:push_til)
        .and_return({ success: false, message: "一時的なエラー" })

      visit diary_path(diary)

      click_button "GitHubにアップロード"

      expect(page).to have_content("一時的なエラー")
      expect(page).to have_button("再試行")
    end
  end

  describe "security considerations", js: true do
    it "does not expose access tokens in the UI" do
      visit github_settings_path

      expect(page).not_to have_content(user.access_token)
      expect(page).not_to have_content("token")
    end

    it "logs security events appropriately" do
      allow(Rails.logger).to receive(:info)

      visit diary_path(diary)
      click_button "GitHubにアップロード"

      expect(Rails.logger).to have_received(:info).with(/GitHub operation/)
    end

    it "handles malicious repository names safely" do
      visit github_settings_path

      fill_in "github_repo_name", with: "<script>alert('xss')</script>"
      click_button "リポジトリを作成"

      expect(page).not_to have_content("<script>")
    end
  end

  describe "integration with diary workflow" do
    it "integrates GitHub upload with diary completion" do
      user.update!(github_repo_name: "test-til")
      allow(mock_github_service).to receive(:push_til)
        .and_return({ success: true, message: "アップロード成功" })

      visit new_diary_path

      # Fill in diary form
      page.all("input[type='radio']").first.choose
      fill_in "diary[notes]", with: "テスト日記"

      click_button "日記を作成"

      # After diary creation, upload button should be available
      expect(page).to have_button("GitHubにアップロード")
    end

    it "shows GitHub status in diary summary" do
      uploaded_diary = create(:diary, :github_uploaded, user: user)
      
      visit diaries_path

      expect(page).to have_content("GitHub: アップロード済み")
    end
  end
end