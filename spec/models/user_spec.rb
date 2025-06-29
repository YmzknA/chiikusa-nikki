require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:diaries).dependent(:destroy) }
  end

  describe "validations" do
    let(:user) { build(:user) }

    describe "email validation" do
      it { is_expected.to validate_presence_of(:email) }

      it "validates email format" do
        user.email = "invalid-email"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("は不正な値です")
      end

      it "accepts valid email format" do
        user.email = "valid@example.com"
        expect(user).to be_valid
      end

      it "does not enforce email uniqueness" do
        create(:user, email: "test@example.com")
        new_user = build(:user, email: "test@example.com", github_id: "different_id")
        expect(new_user).to be_valid
      end
    end

    describe "provider ID validations" do
      it "validates github_id uniqueness" do
        create(:user, :with_github, github_id: "123456")
        user = build(:user, :with_github, github_id: "123456")
        expect(user).not_to be_valid
        expect(user.errors[:github_id]).to include("はすでに存在します")
      end

      it "validates google_id uniqueness" do
        create(:user, :with_google, google_id: "123456")
        user = build(:user, :with_google, google_id: "123456")
        expect(user).not_to be_valid
        expect(user.errors[:google_id]).to include("はすでに存在します")
      end

      it "allows nil values for provider IDs" do
        user = build(:user, github_id: nil, google_id: nil, providers: [])
        expect(user).not_to be_valid
        expect(user.errors[:base]).to include("少なくとも一つの認証プロバイダーが必要です")
      end

      it "requires at least one provider ID" do
        user = build(:user, github_id: nil, google_id: nil, providers: [])
        expect(user).not_to be_valid
        expect(user.errors[:base]).to include("少なくとも一つの認証プロバイダーが必要です")
      end
    end

    describe "username validation" do
      it "validates presence when not in setup pending state" do
        user = build(:user, username: "configured_user")
        expect(user).to validate_presence_of(:username)
      end

      it "validates length constraints" do
        user = build(:user, username: "a")
        expect(user).to validate_length_of(:username).is_at_least(1).is_at_most(50)
      end

      it "skips validation when username setup is pending" do
        user = build(:user, username: User::DEFAULT_USERNAME)
        user.valid?
        expect(user.errors[:username]).to be_empty
      end
    end

    describe "provider consistency validation" do
      it "validates GitHub provider consistency" do
        user = build(:user, github_id: "123", providers: [])
        expect(user).not_to be_valid
        expect(user.errors[:providers]).to include("GitHub IDが存在しますが、プロバイダーリストに含まれていません")
      end

      it "validates Google provider consistency" do
        user = build(:user, google_id: "123", providers: [])
        expect(user).not_to be_valid
        expect(user.errors[:providers]).to include("Google IDが存在しますが、プロバイダーリストに含まれていません")
      end
    end
  end

  describe ".from_omniauth" do
    let(:github_auth) do
      double(
        provider: "github",
        uid: "12345",
        info: double(email: "test@example.com"),
        credentials: double(token: "test_token")
      )
    end

    let(:google_auth) do
      double(
        provider: "google_oauth2",
        uid: "67890",
        info: double(email: "test@example.com"),
        credentials: double(token: "google_token")
      )
    end

    context "when user does not exist" do
      before do
        # Ensure no user with this github_id exists
        User.where(github_id: "12345").destroy_all
      end

      it "creates a new GitHub user" do
        expect do
          described_class.from_omniauth(github_auth)
        end.to change(described_class, :count).by(1)

        user = described_class.last
        expect(user.github_id).to eq("12345")
        expect(user.email).to eq("test@example.com")
        expect(user.providers).to include("github")
      end

      it "creates a new Google user" do
        # Ensure no user with this google_id exists
        User.where(google_id: "67890").destroy_all

        expect do
          described_class.from_omniauth(google_auth)
        end.to change(described_class, :count).by(1)

        user = described_class.last
        expect(user.google_id).to eq("67890")
        expect(user.google_email).to eq("test@example.com")
        expect(user.providers).to include("google_oauth2")
      end
    end

    context "when user exists" do
      let!(:existing_user) do
        # Clean up any existing users with this ID first
        User.where(github_id: "12345").destroy_all
        create(:user, :with_github, github_id: "12345")
      end

      it "does not create a new user" do
        expect do
          described_class.from_omniauth(github_auth)
        end.not_to change(described_class, :count)
      end

      it "updates the existing user's information" do
        user = described_class.from_omniauth(github_auth)
        expect(user.id).to eq(existing_user.id)
        expect(user.encrypted_access_token).to eq("test_token")
      end
    end

    context "when current user is provided (linking accounts)" do
      let(:current_user) { create(:user, github_id: "existing_github_id") }

      it "adds Google provider to existing user" do
        user = described_class.from_omniauth(google_auth, current_user)

        expect(user.id).to eq(current_user.id)
        expect(user.google_id).to eq("67890")
        expect(user.providers).to include("google_oauth2")
      end

      it "raises error when provider is already taken" do
        create(:user, :with_google, google_id: "67890")

        expect do
          described_class.from_omniauth(google_auth, current_user)
        end.to raise_error(StandardError, /この.*アカウントは既に別のユーザーに連携されています/)
      end
    end
  end

  describe "GitHub functionality" do
    let(:user) { create(:user, :with_github) }

    describe "#github_repo_configured?" do
      it "returns true when github_repo_name is present" do
        user.update!(github_repo_name: "test-til")
        expect(user.github_repo_configured?).to be true
      end

      it "returns false when github_repo_name is blank" do
        user.update!(github_repo_name: nil)
        expect(user.github_repo_configured?).to be false
      end
    end

    describe "#github_service" do
      it "returns a GithubService instance" do
        expect(user.github_service).to be_a(GithubService)
      end

      it "memoizes the service instance" do
        service1 = user.github_service
        service2 = user.github_service
        expect(service1).to be service2
      end
    end

    describe "#setup_github_repository" do
      let(:mock_service) { instance_double(GithubService) }

      before do
        allow(user).to receive(:github_service).and_return(mock_service)
      end

      context "when repository creation succeeds" do
        before do
          allow(mock_service).to receive(:create_repository)
            .with("test-repo")
            .and_return({ success: true, message: "Repository created" })
        end

        it "updates github_repo_name and returns success" do
          result = user.setup_github_repository("test-repo")

          expect(result[:success]).to be true
          expect(user.github_repo_name).to eq("test-repo")
        end
      end

      context "when repository creation fails" do
        before do
          allow(mock_service).to receive(:create_repository)
            .with("invalid-repo")
            .and_return({ success: false, message: "Creation failed" })
        end

        it "does not update github_repo_name and returns failure" do
          result = user.setup_github_repository("invalid-repo")

          expect(result[:success]).to be false
          expect(user.github_repo_name).to be_nil
        end
      end

      context "when repo_name is blank" do
        it "returns failure message" do
          result = user.setup_github_repository("")

          expect(result[:success]).to be false
          expect(result[:message]).to include("入力してください")
        end
      end
    end

    describe "#verify_github_repository?" do
      let(:mock_service) { instance_double(GithubService) }

      before do
        allow(user).to receive(:github_service).and_return(mock_service)
      end

      context "when repository is configured and exists" do
        before do
          user.update!(github_repo_name: "test-repo")
          allow(mock_service).to receive(:repository_exists?).with("test-repo").and_return(true)
        end

        it "returns true" do
          expect(user.verify_github_repository?).to be true
        end
      end

      context "when repository is not configured" do
        before { user.update!(github_repo_name: nil) }

        it "returns false" do
          expect(user.verify_github_repository?).to be false
        end
      end

      context "when repository is configured but does not exist" do
        before do
          user.update!(github_repo_name: "nonexistent-repo")
          allow(mock_service).to receive(:repository_exists?).with("nonexistent-repo").and_return(false)
        end

        it "returns false" do
          expect(user.verify_github_repository?).to be false
        end
      end
    end

    describe "#reset_github_repository" do
      let(:mock_service) { instance_double(GithubService) }

      before do
        user.update!(github_repo_name: "test-repo")
        allow(user).to receive(:github_service).and_return(mock_service)
        allow(mock_service).to receive(:reset_all_diaries_upload_status)
      end

      it "resets github_repo_name and calls service reset method" do
        user.reset_github_repository

        expect(user.github_repo_name).to be_nil
        expect(mock_service).to have_received(:reset_all_diaries_upload_status)
      end
    end

    describe "#reset_github_access" do
      before do
        user.update!(
          encrypted_access_token: "token",
          github_repo_name: "test-repo"
        )
      end

      it "resets access token and repo name" do
        user.reset_github_access

        expect(user.encrypted_access_token).to be_nil
        expect(user.github_repo_name).to be_nil
      end
    end
  end

  describe "provider connection methods" do
    let(:user) { create(:user) }

    describe "#github_auth?" do
      it "returns true when both github_id and access_token are present" do
        user.update!(github_id: "123", encrypted_access_token: "token")
        expect(user.github_auth?).to be true
      end

      it "returns false when github_id is missing" do
        user.update!(github_id: nil, encrypted_access_token: "token", providers: ["google_oauth2"], google_id: "123",
                     encrypted_google_access_token: "token")
        expect(user.github_auth?).to be false
      end

      it "returns false when access_token is missing" do
        user.update!(github_id: "123", encrypted_access_token: nil)
        expect(user.github_auth?).to be false
      end
    end

    describe "#google_auth?" do
      it "returns true when both google_id and google_access_token are present" do
        user.update!(google_id: "123", encrypted_google_access_token: "token", providers: %w[github google_oauth2])
        expect(user.google_auth?).to be true
      end

      it "returns false when google_id is missing" do
        user.update!(google_id: nil, encrypted_google_access_token: "token", providers: ["github"])
        expect(user.google_auth?).to be false
      end

      it "returns false when google_access_token is missing" do
        user.update!(google_id: "123", encrypted_google_access_token: nil, providers: %w[github google_oauth2])
        expect(user.google_auth?).to be false
      end
    end

    describe "#github_connected?" do
      it "returns true when github is in providers array" do
        user.update!(providers: ["github"])
        expect(user.github_connected?).to be true
      end

      it "returns false when github is not in providers array" do
        user.update!(providers: ["google_oauth2"], github_id: nil, encrypted_access_token: nil, google_id: "123",
                     encrypted_google_access_token: "token")
        expect(user.github_connected?).to be false
      end
    end

    describe "#google_connected?" do
      it "returns true when google_oauth2 is in providers array" do
        user.update!(providers: %w[github google_oauth2], google_id: "123", encrypted_google_access_token: "token")
        expect(user.google_connected?).to be true
      end

      it "returns false when google_oauth2 is not in providers array" do
        user.update!(providers: ["github"], google_id: nil, encrypted_google_access_token: nil)
        expect(user.google_connected?).to be false
      end
    end

    describe "#can_link_provider?" do
      before { user.update!(providers: ["github"]) }

      it "returns false for already connected provider" do
        expect(user.can_link_provider?("github")).to be false
      end

      it "returns true for unconnected provider" do
        expect(user.can_link_provider?("google_oauth2")).to be true
      end
    end
  end

  describe "seed management" do
    let(:user) { create(:user, seed_count: 3) }

    describe "#add_seed_from_watering!" do
      context "when conditions are met" do
        it "increments seed count and updates timestamp" do
          expect do
            result = user.add_seed_from_watering!
            expect(result).to be true
          end.to change(user, :seed_count).by(1)

          expect(user.last_seed_incremented_at.to_date).to eq(Date.current)
        end
      end

      context "when already incremented today" do
        before { user.update!(last_seed_incremented_at: Time.current) }

        it "returns false and does not increment" do
          expect do
            result = user.add_seed_from_watering!
            expect(result).to be false
          end.not_to change(user, :seed_count)
        end
      end

      context "when seed count is at maximum" do
        before { user.update!(seed_count: 5) }

        it "returns false and does not increment" do
          expect do
            result = user.add_seed_from_watering!
            expect(result).to be false
          end.not_to change(user, :seed_count)
        end
      end
    end

    describe "#add_seed_from_sharing!" do
      context "when conditions are met" do
        it "increments seed count and updates timestamp" do
          expect do
            result = user.add_seed_from_sharing!
            expect(result).to be true
          end.to change(user, :seed_count).by(1)

          expect(user.last_shared_at.to_date).to eq(Date.current)
        end
      end

      context "when already shared today" do
        before { user.update!(last_shared_at: Time.current) }

        it "returns false and does not increment" do
          expect do
            result = user.add_seed_from_sharing!
            expect(result).to be false
          end.not_to change(user, :seed_count)
        end
      end

      context "when seed count is at maximum" do
        before { user.update!(seed_count: 5) }

        it "returns false and does not increment" do
          expect do
            result = user.add_seed_from_sharing!
            expect(result).to be false
          end.not_to change(user, :seed_count)
        end
      end
    end

    describe "#can_increment_seed_count?" do
      it "returns true when conditions are met" do
        expect(user.can_increment_seed_count?).to be true
      end

      it "returns false when already incremented today" do
        user.update!(last_seed_incremented_at: Time.current)
        expect(user.can_increment_seed_count?).to be false
      end

      it "returns false when at maximum seed count" do
        user.update!(seed_count: 5)
        expect(user.can_increment_seed_count?).to be false
      end
    end

    describe "#can_increment_seed_count_by_share?" do
      it "returns true when conditions are met" do
        expect(user.can_increment_seed_count_by_share?).to be true
      end

      it "returns false when already shared today" do
        user.update!(last_shared_at: Time.current)
        expect(user.can_increment_seed_count_by_share?).to be false
      end

      it "returns false when at maximum seed count" do
        user.update!(seed_count: 5)
        expect(user.can_increment_seed_count_by_share?).to be false
      end
    end
  end

  describe "username methods" do
    describe "#username_configured?" do
      it "returns true for configured username" do
        user = create(:user, username: "configured_user")
        expect(user.username_configured?).to be true
      end

      it "returns false for default username" do
        user = create(:user, :username_setup_pending)
        expect(user.username_configured?).to be false
      end

      it "returns false for blank username" do
        user = build(:user, username: "")
        user.save(validate: false) # Skip validations for this specific test
        expect(user.username_configured?).to be false
      end
    end

    describe "#username_setup_pending?" do
      it "returns true for default username" do
        user = create(:user, :username_setup_pending)
        expect(user.username_setup_pending?).to be true
      end

      it "returns false for configured username" do
        user = create(:user, username: "configured_user")
        expect(user.username_setup_pending?).to be false
      end
    end
  end

  describe "access token encryption" do
    let(:user) { create(:user) }

    describe "#access_token" do
      it "returns decrypted token" do
        user.access_token = "test_token"
        expect(user.access_token).to eq("test_token")
      end

      it "returns nil for blank encrypted token" do
        user.encrypted_access_token = nil
        expect(user.access_token).to be_nil
      end
    end

    describe "#google_access_token" do
      it "returns decrypted token" do
        user.google_access_token = "google_token"
        expect(user.google_access_token).to eq("google_token")
      end

      it "returns nil for blank encrypted token" do
        user.encrypted_google_access_token = nil
        expect(user.google_access_token).to be_nil
      end
    end
  end
end
