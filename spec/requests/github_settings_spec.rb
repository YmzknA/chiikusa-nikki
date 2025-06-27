require "rails_helper"

RSpec.describe "GithubSettings", type: :request do
  let(:user) do
    User.create!(
      email: "test@example.com",
      password: "password",
      github_id: "123456",
      username: "testuser",
      access_token: "test_token"
    )
  end

  before do
    # Stub current_user for authentication
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "GET /github_settings" do
    it "returns http success" do
      get "/github_settings"
      expect(response).to have_http_status(:success)
    end

    context "when user has repository configured" do
      before do
        user.update!(github_repo_name: "test-til")
        allow(user).to receive(:verify_github_repository).and_return(true)
      end

      it "assigns @repo_exists as true" do
        get "/github_settings"
        expect(assigns(:repo_exists)).to be true
      end
    end

    context "when repository doesn't exist" do
      let(:mock_service) { instance_double(GithubService) }

      before do
        user.update!(github_repo_name: "nonexistent-repo")
        allow(user).to receive(:github_service).and_return(mock_service)
        allow(user).to receive(:verify_github_repository).and_return(false)
        allow(mock_service).to receive(:reset_all_diaries_upload_status)
      end

      it "resets upload status and shows alert" do
        get "/github_settings"

        expect(mock_service).to have_received(:reset_all_diaries_upload_status)
        expect(flash[:alert]).to include("見つかりません")
      end
    end
  end

  describe "PATCH /github_settings" do
    context "with valid repository name" do
      let(:mock_service) { instance_double(GithubService) }

      before do
        allow(user).to receive(:setup_github_repository).and_return({ success: true, message: "Repository created" })
      end

      it "creates repository and redirects with success message" do
        patch "/github_settings", params: { github_repo_name: "new-til-repo" }

        expect(response).to redirect_to(github_settings_path)
        expect(flash[:notice]).to include("Repository created")
      end
    end

    context "with blank repository name" do
      it "redirects with error message" do
        patch "/github_settings", params: { github_repo_name: "" }

        expect(response).to redirect_to(github_settings_path)
        expect(flash[:alert]).to include("入力してください")
      end
    end

    context "when repository creation fails" do
      before do
        allow(user).to receive(:setup_github_repository).and_return({ success: false, message: "Creation failed" })
      end

      it "redirects with error message" do
        patch "/github_settings", params: { github_repo_name: "invalid-repo" }

        expect(response).to redirect_to(github_settings_path)
        expect(flash[:alert]).to include("Creation failed")
      end
    end
  end

  describe "DELETE /github_settings" do
    let(:mock_service) { instance_double(GithubService) }

    before do
      user.update!(github_repo_name: "test-repo")
      allow(user).to receive(:github_service).and_return(mock_service)
      allow(mock_service).to receive(:reset_all_diaries_upload_status)
    end

    it "resets repository configuration and redirects with success message" do
      delete "/github_settings"

      expect(user.reload.github_repo_name).to be_nil
      expect(response).to redirect_to(github_settings_path)
      expect(flash[:notice]).to include("リセットしました")
    end
  end

  context "when user is not authenticated" do
    before do
      # Remove authentication stubs
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_raise(ActionController::RoutingError.new("Not Found"))
    end

    it "raises routing error for GET" do
      expect { get "/github_settings" }.to raise_error(ActionController::RoutingError)
    end

    it "raises routing error for PATCH" do
      expect { patch "/github_settings", params: { github_repo_name: "test" } }.to raise_error(ActionController::RoutingError)
    end

    it "raises routing error for DELETE" do
      expect { delete "/github_settings" }.to raise_error(ActionController::RoutingError)
    end
  end
end
