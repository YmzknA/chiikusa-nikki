require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) do
    user = build(:user, username: nil)
    user.save(validate: false)
    user
  end

  before do
    sign_in user
  end

  describe "GET /setup_username" do
    context "when username is not set" do
      it "returns success" do
        get setup_username_path
        expect(response).to have_http_status(:success)
      end

      it "renders the setup username page" do
        get setup_username_path
        expect(response.body).to include("あなたのお名前を")
      end

      it "does not show sidebar navigation" do
        get setup_username_path
        expect(response.body).not_to include("日記カレンダー")
        expect(response.body).not_to include("統計")
        expect(response.body).not_to include("公開日記")
      end
    end

    context "when username is already set" do
      before do
        user.update(username: "existing_user")
      end

      it "redirects to diaries path" do
        get setup_username_path
        expect(response).to redirect_to(diaries_path)
      end
    end
  end

  describe "PATCH /setup_username" do
    context "with valid username" do
      it "updates the username and redirects to tutorial" do
        patch setup_username_path, params: { user: { username: "new_user" } }
        
        expect(response).to redirect_to(tutorial_path)
        expect(user.reload.username).to eq("new_user")
      end

      it "sets success flash message" do
        patch setup_username_path, params: { user: { username: "new_user" } }
        
        follow_redirect!
        expect(response.body).to include("ユーザー名を設定しました！まずは使い方を確認しましょう")
      end
    end

    context "with invalid username" do
      it "renders setup_username with error" do
        patch setup_username_path, params: { user: { username: "" } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("あなたのお名前を")
      end

      it "does not update the username" do
        patch setup_username_path, params: { user: { username: "" } }
        
        expect(user.reload.username).to be_nil
      end
    end

    context "when username is already set" do
      before do
        user.update(username: "existing_user")
      end

      it "redirects to diaries path" do
        patch setup_username_path, params: { user: { username: "new_user" } }
        
        expect(response).to redirect_to(diaries_path)
      end
    end
  end

  describe "DELETE /users" do
    let!(:diary) { create(:diary, user: user) }

    before do
      user.update(username: "test_user")
    end

    it "deletes the user and all associated data" do
      expect {
        delete users_path
      }.to change(User, :count).by(-1)
        .and change(Diary, :count).by(-1)
    end

    it "signs out the user" do
      delete users_path
      
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("アカウントを削除しました")
    end

    it "shows success message" do
      delete users_path
      
      follow_redirect!
      expect(response.body).to include("アカウントを削除しました")
      expect(response.body).to include("またのご利用をお待ちしております")
    end

    context "when deletion fails" do
      before do
        allow_any_instance_of(User).to receive(:destroy).and_return(false)
      end

      it "redirects to profile with error message" do
        delete users_path
        
        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("アカウントの削除に失敗しました")
      end
    end
  end
end