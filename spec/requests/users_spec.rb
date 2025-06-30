require "rails_helper"

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

    context "with valid username confirmation" do
      it "deletes the user and all associated data" do
        expect do
          delete users_path, params: { confirm_username: "test_user" }
        end.to change(User, :count).by(-1)
                                   .and change(Diary, :count).by(-1)
      end

      it "signs out the user" do
        delete users_path, params: { confirm_username: "test_user" }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("アカウントを削除しました")
      end

      it "shows success message with username" do
        delete users_path, params: { confirm_username: "test_user" }

        follow_redirect!
        expect(response.body).to include("test_userさんのアカウントを削除しました")
        expect(response.body).to include("ご利用ありがとうございました")
      end

      it "logs deletion process" do
        allow(Rails.logger).to receive(:info)

        delete users_path, params: { confirm_username: "test_user" }

        expect(Rails.logger).to have_received(:info).with("User deletion initiated: test_user (ID: #{user.id})")
        expect(Rails.logger).to have_received(:info).with("User deletion completed: test_user")
      end
    end

    context "with invalid username confirmation" do
      it "rejects deletion with wrong username" do
        expect do
          delete users_path, params: { confirm_username: "wrong_user" }
        end.not_to change(User, :count)

        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("ユーザー名の確認が正しくありません")
      end

      it "rejects deletion with empty username" do
        expect do
          delete users_path, params: { confirm_username: "" }
        end.not_to change(User, :count)

        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("ユーザー名の確認が正しくありません")
      end

      it "rejects deletion without username parameter" do
        expect do
          delete users_path
        end.not_to change(User, :count)

        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("ユーザー名の確認が正しくありません")
      end

      it "logs invalid confirmation attempts" do
        allow(Rails.logger).to receive(:warn)

        delete users_path, params: { confirm_username: "wrong_user" }

        expect(Rails.logger).to have_received(:warn).with("Invalid username confirmation for user #{user.id}")
      end
    end

    context "when deletion fails" do
      before do
        allow_any_instance_of(User).to receive(:destroy).and_return(false)
        allow_any_instance_of(User).to receive(:errors).and_return(double(full_messages: ["Test error"]))
      end

      it "redirects to profile with error message" do
        delete users_path, params: { confirm_username: "test_user" }

        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("アカウントの削除に失敗しました")
      end

      it "logs deletion failure" do
        allow(Rails.logger).to receive(:error)

        delete users_path, params: { confirm_username: "test_user" }

        expect(Rails.logger).to have_received(:error).with("User deletion failed: Test error")
      end
    end

    context "security tests" do
      it "prevents unauthorized deletion with GET request" do
        get users_path

        expect(response).to have_http_status(:not_found)
      end

      it "prevents unauthorized deletion with POST request" do
        post users_path

        expect(response).to have_http_status(:not_found)
      end

      it "handles data integrity errors gracefully" do
        error_message = "Integrity error"
        error = ActiveRecord::InvalidForeignKey.new(error_message)
        allow_any_instance_of(User).to receive(:destroy).and_raise(error)

        delete users_path, params: { confirm_username: "test_user" }

        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("関連データの削除に失敗しました")
      end

      it "handles general errors gracefully" do
        error_message = "General error"
        error = StandardError.new(error_message)
        allow_any_instance_of(User).to receive(:destroy).and_raise(error)
        allow(Rails.logger).to receive(:error)

        delete users_path, params: { confirm_username: "test_user" }

        expect(Rails.logger).to have_received(:error).with("User deletion failed: #{error_message}")
        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("アカウントの削除に失敗しました")
      end
    end
  end
end
