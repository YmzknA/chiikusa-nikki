require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, :with_github) }

  before do
    sign_in user
  end

  describe "GET /profile" do
    it "returns http success" do
      get profile_path
      expect(response).to have_http_status(:success)
    end

    it "displays user information" do
      get profile_path
      expect(response.body).to include(user.username)
    end

    it "requires authentication" do
      sign_out user
      get profile_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /profile/edit" do
    it "returns http success" do
      get edit_profile_path
      expect(response).to have_http_status(:success)
    end

    it "loads user data for editing" do
      get edit_profile_path
      expect(assigns(:current_user)).to eq(user)
    end

    it "requires authentication" do
      sign_out user
      get edit_profile_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /profile" do
    let(:update_params) { { user: { username: "updated_username" } } }

    context "with valid parameters" do
      it "updates the user's profile" do
        patch profile_path, params: update_params

        user.reload
        expect(user.username).to eq("updated_username")
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("プロフィールを更新しました")
      end
    end

    context "with invalid parameters" do
      it "renders edit template with errors" do
        update_params[:user][:username] = ""

        patch profile_path, params: update_params

        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not update with invalid username" do
        original_username = user.username
        update_params[:user][:username] = ""

        patch profile_path, params: update_params

        user.reload
        expect(user.username).to eq(original_username)
      end
    end

    it "requires authentication" do
      sign_out user
      patch profile_path, params: update_params
      expect(response).to redirect_to(root_path)
    end
  end

  describe "profile content validation" do
    it "shows GitHub connection status" do
      get profile_path
      expect(response.body).to include("GitHub")
    end

    it "shows Google connection status" do
      user.update!(providers: %w[github google_oauth2], google_id: "google123")
      get profile_path
      expect(response.body).to include("Google")
    end

    it "shows seed count" do
      user.update!(seed_count: 3)
      get profile_path
      expect(response.body).to include("3")
    end
  end
end
