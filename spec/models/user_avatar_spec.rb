require "rails_helper"

RSpec.configure do |config|
  config.before(:each) do
    allow_any_instance_of(AvatarUploader).to receive(:store!).and_return(true)
    allow_any_instance_of(AvatarUploader).to receive(:url).and_return("http://example.com/mock-avatar.jpg")
  end
end

RSpec.describe User, "avatar functionality", type: :model do
  let(:user) { create(:user) }

  describe "#avatar_url" do
    context "when user has uploaded avatar" do
      before do
        user.avatar = fixture_file_upload("spec/fixtures/test_image.jpg", "image/jpeg")
        user.save!
      end

      it "returns the uploaded avatar URL" do
        expect(user.avatar_url).to be_present
        expect(user.avatar_url).to include("mock-avatar")
      end
    end

    context "when user has no uploaded avatar but has GitHub ID" do
      before do
        user.update!(github_id: "12345")
      end

      it "has GitHub avatar URL method" do
        expect(user.github_avatar_url).to eq("https://avatars.githubusercontent.com/u/12345?v=4")
      end
    end

    context "when user has no avatar and no GitHub ID" do
      it "returns nil" do
        expect(user.avatar_url).to be_nil
      end
    end
  end

  describe "#display_avatar_url" do
    context "when avatar_url is present" do
      before do
        allow(user).to receive(:avatar_url).and_return("http://example.com/avatar.jpg")
      end

      it "returns the avatar URL" do
        expect(user.display_avatar_url).to eq("http://example.com/avatar.jpg")
      end
    end

    context "when avatar_url is nil" do
      before do
        allow(user).to receive(:avatar_url).and_return(nil)
      end

      it "returns default avatar URL (nil)" do
        expect(user.display_avatar_url).to be_nil
      end
    end
  end

  describe "#github_avatar_url" do
    context "when GitHub ID is present" do
      before do
        user.github_id = "12345"
      end

      it "returns correct GitHub avatar URL" do
        expect(user.github_avatar_url).to eq("https://avatars.githubusercontent.com/u/12345?v=4")
      end
    end

    context "when GitHub ID is not present" do
      before do
        user.github_id = nil
      end

      it "returns nil" do
        expect(user.github_avatar_url).to be_nil
      end
    end
  end

  describe "#initials" do
    context "when username is set" do
      before do
        user.username = "John Doe"
      end

      it "returns first letters of each word" do
        expect(user.initials).to eq("JD")
      end
    end

    context "when username is single word" do
      before do
        user.username = "John"
      end

      it "returns first letter" do
        expect(user.initials).to eq("J")
      end
    end

    context "when username is default value" do
      before do
        user.username = User::DEFAULT_USERNAME
      end

      it "returns 'U'" do
        expect(user.initials).to eq("U")
      end
    end

    context "when username is blank" do
      before do
        user.username = ""
      end

      it "returns 'U'" do
        expect(user.initials).to eq("U")
      end
    end
  end
end
