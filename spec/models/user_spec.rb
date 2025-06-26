require "rails_helper"

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
        expect do
          described_class.find_or_create_from_auth_hash(auth_hash)
        end.to change(described_class, :count).by(1)
      end
    end

    context "when user exists" do
      before do
        described_class.find_or_create_from_auth_hash(auth_hash)
      end

      it "does not create a new user" do
        expect do
          described_class.find_or_create_from_auth_hash(auth_hash)
        end.not_to change(described_class, :count)
      end

      it "updates the user's information" do
        updated_auth_hash = auth_hash.merge(info: { nickname: "updated_user" })
        user = described_class.find_or_create_from_auth_hash(updated_auth_hash)
        expect(user.username).to eq("updated_user")
      end
    end
  end
end
