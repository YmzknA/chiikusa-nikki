require "rails_helper"

RSpec.describe "Authentication Integration", type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe "OAuth authentication workflows" do
    let(:github_auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'github',
        uid: '12345',
        info: {
          email: 'test@example.com',
          nickname: 'testuser'
        },
        credentials: {
          token: 'github_token_123'
        }
      })
    end

    let(:google_auth_hash) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '67890',
        info: {
          email: 'test@gmail.com',
          name: 'Test User'
        },
        credentials: {
          token: 'google_token_456'
        }
      })
    end

    describe "GitHub OAuth flow" do
      before do
        Rails.application.env_config["omniauth.auth"] = github_auth_hash
      end

      it "creates new user with GitHub authentication" do
        expect do
          get "/users/auth/github/callback"
        end.to change(User, :count).by(1)

        expect(response).to redirect_to(setup_username_path)
        
        user = User.last
        expect(user.email).to eq('test@example.com')
        expect(user.github_id).to eq('12345')
        expect(user.encrypted_access_token).to eq('github_token_123')
        expect(user.providers).to include('github')
        expect(user.username).to eq(User::DEFAULT_USERNAME)
      end

      it "authenticates existing GitHub user" do
        existing_user = create(:user, :with_github, github_id: '12345')

        expect do
          get "/users/auth/github/callback"
        end.not_to change(User, :count)

        expect(response).to redirect_to(diaries_path)
        expect(session[:user_id]).to eq(existing_user.id)
      end

      it "updates user information on subsequent logins" do
        user = create(:user, :with_github, github_id: '12345', encrypted_access_token: 'old_token')

        get "/users/auth/github/callback"

        user.reload
        expect(user.encrypted_access_token).to eq('github_token_123')
      end
    end

    describe "Google OAuth flow" do
      before do
        Rails.application.env_config["omniauth.auth"] = google_auth_hash
      end

      it "creates new user with Google authentication" do
        expect do
          get "/users/auth/google_oauth2/callback"
        end.to change(User, :count).by(1)

        user = User.last
        expect(user.google_id).to eq('67890')
        expect(user.google_email).to eq('test@gmail.com')
        expect(user.encrypted_google_access_token).to eq('google_token_456')
        expect(user.providers).to include('google_oauth2')
      end

      it "authenticates existing Google user" do
        existing_user = create(:user, :with_google, google_id: '67890')

        expect do
          get "/users/auth/google_oauth2/callback"
        end.not_to change(User, :count)

        expect(response).to redirect_to(diaries_path)
        expect(session[:user_id]).to eq(existing_user.id)
      end
    end

    describe "provider linking workflow" do
      let(:existing_user) { create(:user, :with_github, github_id: '12345') }

      before do
        sign_in existing_user
        Rails.application.env_config["omniauth.auth"] = google_auth_hash
      end

      it "links Google account to existing GitHub user" do
        expect do
          get "/users/auth/google_oauth2/callback"
        end.not_to change(User, :count)

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("Googleアカウントを連携しました")

        existing_user.reload
        expect(existing_user.google_id).to eq('67890')
        expect(existing_user.providers).to include('google_oauth2')
        expect(existing_user.providers).to include('github')
      end

      it "prevents linking already linked provider" do
        create(:user, :with_google, google_id: '67890')

        get "/users/auth/google_oauth2/callback"

        expect(response).to redirect_to(profile_path)
        expect(flash[:alert]).to include("既に別のユーザーに連携")
      end

      it "handles provider linking errors gracefully" do
        # Simulate an invalid auth hash
        Rails.application.env_config["omniauth.auth"] = OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: nil
        })

        get "/users/auth/google_oauth2/callback"

        expect(response).to redirect_to(profile_path)
        expect(flash[:alert]).to include("認証の連携に失敗")
      end
    end

    describe "OAuth failure handling" do
      it "handles GitHub OAuth failures" do
        get "/users/auth/failure", params: { provider: 'github' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("GitHubでのログインに失敗")
      end

      it "handles Google OAuth failures" do
        get "/users/auth/failure", params: { provider: 'google_oauth2' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Googleでのログインに失敗")
      end

      it "handles unknown provider failures" do
        get "/users/auth/failure", params: { provider: 'unknown' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("不明なプロバイダーでのログインに失敗")
      end
    end
  end

  describe "username setup workflow" do
    let(:user) { create(:user, :username_setup_pending) }

    before do
      sign_in user
    end

    it "redirects to username setup when required" do
      get diaries_path

      expect(response).to redirect_to(setup_username_path)
    end

    it "allows access to username setup page" do
      get setup_username_path

      expect(response).to have_http_status(:success)
    end

    it "updates username and redirects to diaries" do
      patch users_path, params: { user: { username: 'newusername' } }

      expect(response).to redirect_to(diaries_path)
      expect(user.reload.username).to eq('newusername')
      expect(flash[:notice]).to include("プロフィールを更新")
    end

    it "validates username requirements" do
      patch users_path, params: { user: { username: '' } }

      expect(response).to render_template(:setup_username)
      expect(user.reload.username).to eq(User::DEFAULT_USERNAME)
    end

    it "prevents access to other pages until username is set" do
      [diaries_path, profile_path, stats_path, github_settings_path].each do |path|
        get path
        expect(response).to redirect_to(setup_username_path)
      end
    end

    it "allows access after username is configured" do
      user.update!(username: 'configured_user')

      get diaries_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "authentication state management" do
    let(:user) { create(:user, :with_github) }

    it "maintains session across requests" do
      sign_in user

      get diaries_path
      expect(response).to have_http_status(:success)

      get profile_path
      expect(response).to have_http_status(:success)
      expect(assigns(:current_user)).to eq(user)
    end

    it "handles logout properly" do
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil

      # Accessing protected page should redirect to login
      get diaries_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "expires sessions appropriately" do
      sign_in user

      # Simulate session expiry
      session[:user_id] = nil

      get diaries_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "authentication security measures" do
    it "prevents CSRF attacks on OAuth endpoints" do
      # Attempt to make OAuth request without proper CSRF token
      post "/users/auth/github", headers: { 'X-CSRF-Token' => 'invalid' }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "validates OAuth state parameter" do
      # Test that OAuth flow validates state parameter
      get "/users/auth/github/callback", params: { state: 'invalid_state' }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("認証に失敗")
    end

    it "logs authentication attempts" do
      expect(Rails.logger).to receive(:info).with(/OAuth attempt/)

      Rails.application.env_config["omniauth.auth"] = github_auth_hash
      get "/users/auth/github/callback"
    end

    it "handles malicious OAuth data safely" do
      malicious_auth = OmniAuth::AuthHash.new({
        provider: 'github',
        uid: '<script>alert("xss")</script>',
        info: {
          email: 'test@example.com<script>'
        }
      })

      Rails.application.env_config["omniauth.auth"] = malicious_auth

      expect do
        get "/users/auth/github/callback"
      end.not_to raise_error

      user = User.last
      expect(user.github_id).not_to include('<script>')
    end
  end

  describe "provider consistency validation" do
    it "maintains provider array consistency" do
      user = create(:user, github_id: '12345', providers: ['github'])

      # Add Google provider
      Rails.application.env_config["omniauth.auth"] = google_auth_hash
      sign_in user
      get "/users/auth/google_oauth2/callback"

      user.reload
      expect(user.providers).to contain_exactly('github', 'google_oauth2')
      expect(user.google_id).to eq('67890')
    end

    it "validates provider consistency on user save" do
      user = build(:user, github_id: '12345', providers: [])

      expect(user).not_to be_valid
      expect(user.errors[:providers]).to include("GitHub IDが存在しますが、プロバイダーリストに含まれていません")
    end

    it "requires at least one provider" do
      user = build(:user, github_id: nil, google_id: nil, providers: [])

      expect(user).not_to be_valid
      expect(user.errors[:base]).to include("少なくとも一つの認証プロバイダーが必要です")
    end
  end

  describe "email handling and uniqueness" do
    it "allows same email for different OAuth providers" do
      github_user = create(:user, :with_github, email: 'same@example.com')
      
      google_auth = google_auth_hash.dup
      google_auth.info.email = 'same@example.com'
      Rails.application.env_config["omniauth.auth"] = google_auth

      expect do
        get "/users/auth/google_oauth2/callback"
      end.to change(User, :count).by(1)

      google_user = User.last
      expect(google_user.email).to eq('same@example.com')
      expect(google_user.id).not_to eq(github_user.id)
    end

    it "validates email format during OAuth" do
      invalid_auth = github_auth_hash.dup
      invalid_auth.info.email = 'invalid-email'
      Rails.application.env_config["omniauth.auth"] = invalid_auth

      get "/users/auth/github/callback"

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("認証に失敗")
    end
  end

  describe "redirect behavior after authentication" do
    it "redirects to intended page after login" do
      get diaries_path

      expect(response).to redirect_to(new_user_session_path)
      
      Rails.application.env_config["omniauth.auth"] = github_auth_hash
      get "/users/auth/github/callback"

      # Should redirect to username setup for new users
      expect(response).to redirect_to(setup_username_path)
    end

    it "redirects existing users to diaries after login" do
      user = create(:user, :with_github, github_id: '12345')

      Rails.application.env_config["omniauth.auth"] = github_auth_hash
      get "/users/auth/github/callback"

      expect(response).to redirect_to(diaries_path)
    end

    it "redirects to diaries from root when authenticated" do
      sign_in create(:user, :with_github)

      get root_path

      expect(response).to redirect_to(diaries_path)
    end
  end

  describe "concurrent authentication handling" do
    it "handles multiple simultaneous login attempts" do
      # Simulate concurrent requests with same OAuth data
      Rails.application.env_config["omniauth.auth"] = github_auth_hash

      threads = []
      results = []

      3.times do
        threads << Thread.new do
          result = get "/users/auth/github/callback"
          results << result
        end
      end

      threads.each(&:join)

      # Should only create one user despite concurrent requests
      expect(User.where(github_id: '12345').count).to eq(1)
    end
  end
end