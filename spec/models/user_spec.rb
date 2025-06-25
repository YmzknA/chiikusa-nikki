require 'rails_helper'

RSpec.describe User, type: :model do
  describe ".find_or_create_from_auth_hash" do
    let(:auth_hash) do
      {
        provider: "github",
        uid: "12345",
        info: {
          nickname: "testuser",
          email: "test@example.com"
        },
        credentials: {
          token: "test_token"
        }
      }
    end

    context "when user does not exist" do
      it "creates a new user" do
        expect {
          User.find_or_create_from_auth_hash(auth_hash)
        }.to change(User, :count).by(1)
      end
    end

    context "when user exists" do
      before do
        User.find_or_create_from_auth_hash(auth_hash)
      end

      it "does not create a new user" do
        expect {
          User.find_or_create_from_auth_hash(auth_hash)
        }.not_to change(User, :count)
      end

      it "updates the user's information" do
        updated_auth_hash = auth_hash.merge(info: { nickname: "updated_user" })
        user = User.find_or_create_from_auth_hash(updated_auth_hash)
        expect(user.username).to eq("updated_user")
      end
    end
  end
end
