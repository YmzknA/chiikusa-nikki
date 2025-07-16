require "rails_helper"

RSpec.configure do |config|
  config.before(:each) do
    allow_any_instance_of(AvatarUploader).to receive(:store!).and_return(true)
    allow_any_instance_of(AvatarUploader).to receive(:url).and_return("http://example.com/mock-avatar.jpg")
  end
end

RSpec.describe "Profile Avatar Updates", type: :request do
  let(:user) { create(:user, :with_github) }
  let(:avatar_file) { fixture_file_upload("spec/fixtures/test_image.jpg", "image/jpeg") }

  before do
    sign_in user
  end

  describe "PATCH /profile - avatar update restrictions" do
    context "when updating avatar for the first time" do
      it "allows immediate avatar upload" do
        expect(user.avatar_updated_at).to be_nil

        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("プロフィールを更新しました")
        user.reload
        expect(user.avatar_updated_at).to be_present
      end
    end

    context "when updating avatar for the second time" do
      before do
        # First update
        user.update!(avatar_updated_at: 11.minutes.ago)
      end

      it "allows update after 10 minutes" do
        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("プロフィールを更新しました")
      end

      it "blocks update within 10 minutes" do
        user.update!(avatar_updated_at: 5.minutes.ago)

        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:forbidden)
        expect(flash[:alert]).to include("アバターの変更は10分に1回まで")
        expect(flash[:alert]).to include("あと")
      end

      it "shows remaining time in error message" do
        user.update!(avatar_updated_at: 8.minutes.ago)

        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(flash[:alert]).to match(/あと[12]分お待ちください/)
      end
    end

    context "boundary value testing" do
      it "allows update exactly 10 minutes later" do
        user.update!(avatar_updated_at: 10.minutes.ago)

        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("プロフィールを更新しました")
      end

      it "blocks update just before 10 minutes" do
        user.update!(avatar_updated_at: (10.minutes - 1.second).ago)

        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:forbidden)
        expect(flash[:alert]).to include("アバターの変更は10分に1回まで")
      end

      it "allows update just after 10 minutes" do
        user.update!(avatar_updated_at: (10.minutes + 1.second).ago)

        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("プロフィールを更新しました")
      end

      it "handles time zone correctly" do
        # 異なるタイムゾーンでの境界値テスト
        Time.use_zone("UTC") do
          user.update!(avatar_updated_at: 10.minutes.ago)

          patch profile_path, params: { user: { avatar: avatar_file } }

          expect(response).to redirect_to(profile_path)
        end
      end
    end

    context "when updating only username" do
      it "allows update without avatar restriction" do
        user.update!(avatar_updated_at: 1.minute.ago)

        patch profile_path, params: { user: { username: "new_username" } }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("プロフィールを更新しました")
        user.reload
        expect(user.username).to eq("new_username")
      end
    end

    context "in development environment" do
      before do
        allow(Rails.application.config).to receive(:avatar_update_interval_limit).and_return(10.seconds)
      end

      it "uses shorter interval for testing" do
        user.update!(avatar_updated_at: 15.seconds.ago)

        patch profile_path, params: { user: { avatar: avatar_file } }

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("プロフィールを更新しました")
      end
    end
  end
end
