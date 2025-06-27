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

  describe "GitHub repository methods" do
    let(:user) do
      described_class.create!(
        email: "test@example.com",
        password: "password",
        github_id: "123456",
        username: "testuser",
        access_token: "test_token"
      )
    end

    describe "#github_repo_configured?" do
      context "when github_repo_name is present" do
        before { user.update!(github_repo_name: "test-til") }

        it "returns true" do
          expect(user.github_repo_configured?).to be true
        end
      end

      context "when github_repo_name is blank" do
        before { user.update!(github_repo_name: nil) }

        it "returns false" do
          expect(user.github_repo_configured?).to be false
        end
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

    describe "#verify_github_repository" do
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
          expect(user.verify_github_repository).to be true
        end
      end

      context "when repository is not configured" do
        before { user.update!(github_repo_name: nil) }

        it "returns false" do
          expect(user.verify_github_repository).to be false
        end
      end

      context "when repository is configured but does not exist" do
        before do
          user.update!(github_repo_name: "nonexistent-repo")
          allow(mock_service).to receive(:repository_exists?).with("nonexistent-repo").and_return(false)
        end

        it "returns false" do
          expect(user.verify_github_repository).to be false
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
  end
end
