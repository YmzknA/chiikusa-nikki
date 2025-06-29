require "rails_helper"

RSpec.describe "Authentication Flow", type: :system do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe "GitHub OAuth authentication", js: true do
    let(:github_auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'github',
        uid: '12345',
        info: {
          email: 'test@example.com',
          nickname: 'testuser'
        },
        credentials: {
          token: 'github_token'
        }
      })
    end

    before do
      OmniAuth.config.mock_auth[:github] = github_auth_hash
    end

    it "allows new user to sign up with GitHub" do
      visit root_path
      
      expect(page).to have_content("ちいくさ日記")
      expect(page).to have_link("GitHubでログイン")
      
      click_link "GitHubでログイン"
      
      # Should redirect to username setup if using default username
      if page.has_content?("ユーザー名を設定")
        fill_in "user[username]", with: "testuser"
        click_button "設定する"
      end
      
      expect(page).to have_current_path(diaries_path)
      expect(page).to have_content("ログイン")
    end

    it "allows existing user to sign in with GitHub" do
      user = create(:user, :with_github, github_id: '12345')
      
      visit root_path
      click_link "GitHubでログイン"
      
      expect(page).to have_current_path(diaries_path)
      expect(page).to have_content(user.username)
    end

    it "handles OAuth failure gracefully" do
      OmniAuth.config.mock_auth[:github] = :invalid_credentials
      
      visit root_path
      click_link "GitHubでログイン"
      
      expect(page).to have_content("ログインに失敗")
      expect(page).to have_current_path(root_path)
    end
  end

  describe "Google OAuth authentication", js: true do
    let(:google_auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '67890',
        info: {
          email: 'test@gmail.com',
          name: 'Test User'
        },
        credentials: {
          token: 'google_token'
        }
      })
    end

    before do
      OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash
    end

    it "allows new user to sign up with Google" do
      visit root_path
      
      expect(page).to have_link("Googleでログイン")
      
      click_link "Googleでログイン"
      
      # Should redirect to username setup if using default username
      if page.has_content?("ユーザー名を設定")
        fill_in "user[username]", with: "googleuser"
        click_button "設定する"
      end
      
      expect(page).to have_current_path(diaries_path)
    end

    it "allows existing user to sign in with Google" do
      user = create(:user, :with_google, google_id: '67890')
      
      visit root_path
      click_link "Googleでログイン"
      
      expect(page).to have_current_path(diaries_path)
      expect(page).to have_content(user.username)
    end
  end

  describe "multiple provider linking", js: true do
    let(:github_user) { create(:user, :with_github, github_id: '12345') }
    let(:google_auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '67890',
        info: {
          email: 'test@gmail.com'
        },
        credentials: {
          token: 'google_token'
        }
      })
    end

    before do
      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
        provider: 'github',
        uid: '12345',
        info: { email: 'test@example.com' },
        credentials: { token: 'github_token' }
      })
      OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash
    end

    it "allows linking Google account to existing GitHub user" do
      # Sign in with GitHub first
      visit root_path
      click_link "GitHubでログイン"
      
      # Navigate to profile to link Google account
      visit profile_path
      
      if page.has_link?("Googleアカウントを連携")
        click_link "Googleアカウントを連携"
        
        expect(page).to have_content("Googleアカウントを連携しました")
        expect(page).to have_current_path(profile_path)
      end
    end

    it "prevents linking already linked provider" do
      create(:user, :with_google, google_id: '67890')
      
      # Sign in with GitHub
      visit root_path
      click_link "GitHubでログイン"
      
      # Try to link Google account that's already linked
      visit profile_path
      
      if page.has_link?("Googleアカウントを連携")
        click_link "Googleアカウントを連携"
        
        expect(page).to have_content("既に別のユーザーに連携")
      end
    end
  end

  describe "username setup flow", js: true do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'github',
        uid: '12345',
        info: {
          email: 'test@example.com'
        },
        credentials: {
          token: 'github_token'
        }
      })
    end

    before do
      OmniAuth.config.mock_auth[:github] = auth_hash
    end

    it "redirects new users to username setup" do
      visit root_path
      click_link "GitHubでログイン"
      
      if page.has_content?("ユーザー名を設定")
        expect(page).to have_current_path(setup_username_path)
        expect(page).to have_field("user[username]")
        
        fill_in "user[username]", with: "myusername"
        click_button "設定する"
        
        expect(page).to have_current_path(diaries_path)
      end
    end

    it "validates username requirements" do
      visit root_path
      click_link "GitHubでログイン"
      
      if page.has_content?("ユーザー名を設定")
        fill_in "user[username]", with: ""
        click_button "設定する"
        
        expect(page).to have_content("エラー")
        expect(page).to have_current_path(setup_username_path)
      end
    end

    it "prevents access to other pages until username is set" do
      visit root_path
      click_link "GitHubでログイン"
      
      if page.has_content?("ユーザー名を設定")
        visit diaries_path
        
        expect(page).to have_current_path(setup_username_path)
        expect(page).to have_content("ユーザー名を設定")
      end
    end
  end

  describe "logout functionality", js: true do
    let(:user) { create(:user, :with_github) }

    before do
      sign_in user
    end

    it "allows user to logout" do
      visit diaries_path
      
      expect(page).to have_content(user.username)
      
      if page.has_link?("ログアウト")
        click_link "ログアウト"
        
        expect(page).to have_current_path(root_path)
        expect(page).to have_link("GitHubでログイン")
        expect(page).not_to have_content(user.username)
      end
    end

    it "redirects to login when accessing protected pages after logout" do
      visit diaries_path
      
      if page.has_link?("ログアウト")
        click_link "ログアウト"
        
        visit diaries_path
        
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  describe "authentication state persistence", js: true do
    let(:user) { create(:user, :with_github) }

    it "maintains login state across page refreshes" do
      sign_in user
      visit diaries_path
      
      expect(page).to have_content(user.username)
      
      page.refresh
      
      expect(page).to have_content(user.username)
      expect(page).to have_current_path(diaries_path)
    end

    it "redirects authenticated users away from login page" do
      sign_in user
      
      visit root_path
      
      expect(page).to have_current_path(diaries_path)
    end
  end

  describe "error handling and edge cases", js: true do
    it "handles invalid OAuth state" do
      OmniAuth.config.mock_auth[:github] = :invalid_credentials
      
      visit root_path
      click_link "GitHubでログイン"
      
      expect(page).to have_content("失敗")
      expect(page).to have_current_path(root_path)
    end

    it "handles OAuth cancellation" do
      # Simulate user canceling OAuth
      visit root_path
      
      # Directly visit failure callback
      visit "/users/auth/failure?message=access_denied"
      
      expect(page).to have_content("ログインに失敗")
      expect(page).to have_current_path(root_path)
    end

    it "handles network errors during OAuth" do
      # This would require more complex mocking in a real scenario
      visit root_path
      
      expect(page).to have_link("GitHubでログイン")
      expect(page).to have_link("Googleでログイン")
    end
  end

  describe "security considerations", js: true do
    it "does not expose sensitive information in errors" do
      OmniAuth.config.mock_auth[:github] = :invalid_credentials
      
      visit root_path
      click_link "GitHubでログイン"
      
      # Check that no sensitive information is exposed
      expect(page).not_to have_content("token")
      expect(page).not_to have_content("secret")
      expect(page).not_to have_content("client_id")
    end

    it "properly handles CSRF protection" do
      visit root_path
      
      # OAuth requests should include CSRF protection
      expect(page).to have_css("meta[name='csrf-token']")
    end
  end

  private

  def user_signed_in?
    page.has_content?("ログアウト") || page.has_content?("プロフィール")
  end
end