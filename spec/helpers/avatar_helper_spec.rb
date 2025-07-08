require 'rails_helper'

RSpec.describe AvatarHelper, type: :helper do
  let(:user) { create(:user, username: "Test User") }

  describe "#avatar_image" do
    context "when user has avatar URL" do
      before do
        allow(user).to receive(:avatar_url).and_return("http://example.com/avatar.jpg")
      end

      it "returns image tag with avatar URL" do
        result = helper.avatar_image(user)
        expect(result).to include("img")
        expect(result).to include("http://example.com/avatar.jpg")
        expect(result).to include("alt=\"Test User\"")
        expect(result).to include("class=\"rounded-full\"")
      end

      it "accepts custom size and CSS class" do
        result = helper.avatar_image(user, size: 50, css_class: "custom-class")
        expect(result).to include("50x50")
        expect(result).to include("custom-class")
      end
    end

    context "when user has no avatar URL" do
      before do
        allow(user).to receive(:avatar_url).and_return(nil)
      end

      it "returns initial avatar div" do
        result = helper.avatar_image(user)
        expect(result).to include("TU") # Test User initials
        expect(result).to include("bg-green-500")
        expect(result).to include("text-white")
      end
    end
  end

  describe "#avatar_initial" do
    it "returns div with user initials" do
      result = helper.avatar_initial(user)
      expect(result).to include("TU")
      expect(result).to include("bg-green-500 text-white")
      expect(result).to include("width: 40px; height: 40px;")
    end

    it "accepts custom size and CSS class" do
      result = helper.avatar_initial(user, size: 60, css_class: "square")
      expect(result).to include("width: 60px; height: 60px;")
      expect(result).to include("square")
    end
  end

  describe "#avatar_url" do
    context "when user has avatar URL" do
      before do
        allow(user).to receive(:avatar_url).and_return("http://example.com/avatar.jpg")
      end

      it "returns the avatar URL" do
        expect(helper.avatar_url(user)).to eq("http://example.com/avatar.jpg")
      end
    end

    context "when user has no avatar URL" do
      before do
        allow(user).to receive(:avatar_url).and_return(nil)
      end

      it "returns nil" do
        expect(helper.avatar_url(user)).to be_nil
      end
    end
  end
end
