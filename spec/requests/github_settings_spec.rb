require "rails_helper"

RSpec.describe "GithubSettings", type: :request do
  let(:user) { create(:user, :with_github) }

  before do
    sign_in user
  end

  describe "GET /github_settings" do
    it "returns http success" do
      get github_settings_path
      expect(response).to have_http_status(:success)
    end

    it "checks repository status when configured" do
      user.update!(github_repo_name: "test-repo")
      mock_service = instance_double(GithubService)
      allow(user).to receive(:github_service).and_return(mock_service)
      allow(mock_service).to receive(:repository_exists?).and_return(true)
      allow(mock_service).to receive(:test_github_connection).and_return({ success: true })

      get github_settings_path

      expect(assigns(:repo_exists)).to be true
      expect(assigns(:connection_test_result)).to be_present
    end

    it "handles missing repository gracefully" do
      user.update!(github_repo_name: "nonexistent-repo")
      mock_service = instance_double(GithubService)
      allow(user).to receive(:github_service).and_return(mock_service)
      allow(mock_service).to receive(:repository_exists?).and_return(false)
      allow(mock_service).to receive(:test_github_connection).and_return({ success: false })

      get github_settings_path

      expect(assigns(:repo_exists)).to be false
      expect(flash.now[:alert]).to include("見つかりません")
    end

    it "requires authentication" do
      sign_out user
      get github_settings_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /github_settings" do
    let(:mock_service) { instance_double(GithubService) }

    before do
      allow(user).to receive(:github_service).and_return(mock_service)
    end

    context "with valid repository name" do
      it "sets up repository successfully" do
        allow(mock_service).to receive(:create_repository)
          .with("test-repo")
          .and_return({ success: true, message: "Repository created" })

        patch github_settings_path, params: { github_repo_name: "test-repo" }

        expect(response).to redirect_to(github_settings_path)
        expect(flash[:notice]).to include("Repository created")
        expect(user.reload.github_repo_name).to eq("test-repo")
      end

      it "handles repository creation failure" do
        allow(mock_service).to receive(:create_repository)
          .with("invalid-repo")
          .and_return({ success: false, message: "Creation failed" })

        patch github_settings_path, params: { github_repo_name: "invalid-repo" }

        expect(response).to redirect_to(github_settings_path)
        expect(flash[:alert]).to include("Creation failed")
        expect(user.reload.github_repo_name).to be_nil
      end

      it "handles authentication requirement" do
        allow(mock_service).to receive(:create_repository)
          .with("auth-repo")
          .and_return({ success: false, requires_reauth: true, message: "Reauth required" })

        patch github_settings_path, params: { github_repo_name: "auth-repo" }

        expect(response).to redirect_to("/users/auth/github")
        expect(flash[:alert]).to include("Reauth required")
      end
    end

    context "with invalid parameters" do
      it "rejects blank repository name" do
        patch github_settings_path, params: { github_repo_name: "" }

        expect(response).to redirect_to(github_settings_path)
        expect(flash[:alert]).to include("入力してください")
      end

      it "rejects whitespace-only repository name" do
        patch github_settings_path, params: { github_repo_name: "   " }

        expect(response).to redirect_to(github_settings_path)
        expect(flash[:alert]).to include("入力してください")
      end
    end

    it "requires authentication" do
      sign_out user
      patch github_settings_path, params: { github_repo_name: "test-repo" }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /github_settings" do
    before do
      user.update!(github_repo_name: "test-repo")
    end

    it "resets GitHub repository settings" do
      delete github_settings_path

      expect(response).to redirect_to(github_settings_path)
      expect(flash[:notice]).to include("リセットしました")
      expect(user.reload.github_repo_name).to be_nil
    end

    it "requires authentication" do
      sign_out user
      delete github_settings_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "repository status checking" do
    let(:mock_service) { instance_double(GithubService) }

    before do
      allow(user).to receive(:github_service).and_return(mock_service)
    end

    it "shows success when repository exists" do
      user.update!(github_repo_name: "existing-repo")
      allow(mock_service).to receive(:repository_exists?).and_return(true)
      allow(mock_service).to receive(:test_github_connection).and_return({ success: true })

      get github_settings_path

      expect(assigns(:repo_exists)).to be true
      expect(flash.now[:alert]).to be_nil
    end

    it "handles connection test failure" do
      user.update!(github_repo_name: "test-repo")
      allow(mock_service).to receive(:repository_exists?).and_return(true)
      allow(mock_service).to receive(:test_github_connection).and_raise(StandardError, "Connection failed")

      get github_settings_path

      expect(assigns(:connection_test_result)).to eq({ success: false, message: "接続テストでエラーが発生しました" })
    end
  end

  describe "without GitHub authentication" do
    let(:user_without_github) { create(:user, :with_google) }

    before do
      sign_in user_without_github
    end

    it "handles missing access token" do
      get github_settings_path

      expect(response).to have_http_status(:success)
      expect(assigns(:repo_exists)).to be false
      expect(assigns(:connection_test_result)).to be_nil
    end
  end
end
