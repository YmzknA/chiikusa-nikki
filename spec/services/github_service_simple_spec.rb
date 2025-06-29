require "rails_helper"

RSpec.describe GithubService, type: :service do
  let(:user) { create(:user, :with_github) }
  let(:service) { described_class.new(user) }
  let(:mock_client) { instance_double(Octokit::Client) }

  before do
    allow(Octokit::Client).to receive(:new).and_return(mock_client)
  end

  describe "#repository_exists?" do
    context "when repository exists" do
      before do
        allow(mock_client).to receive(:repository).and_return(double(full_name: "user/repo"))
      end

      it "returns true" do
        expect(service.repository_exists?("test-repo")).to be true
      end
    end

    context "when repository does not exist" do
      before do
        allow(mock_client).to receive(:repository).and_raise(Octokit::NotFound)
      end

      it "returns false" do
        expect(service.repository_exists?("test-repo")).to be false
      end
    end
  end

  describe "#create_repository" do
    context "when creation succeeds" do
      before do
        allow(service).to receive(:validate_repository_creation).and_return(nil)
        allow(service).to receive(:perform_repository_creation)
          .and_return({ success: true, message: "Repository created" })
      end

      it "returns success result" do
        result = service.create_repository("test-repo")
        expect(result[:success]).to be true
      end
    end
  end

  describe "#push_til" do
    let(:diary) { create(:diary, :with_selected_til, user: user) }

    before do
      user.update!(github_repo_name: "test-repo")
    end

    context "when push succeeds" do
      before do
        allow(service).to receive(:create_or_update_file)
          .and_return({ success: true, commit_sha: "abc123" })
      end

      it "uploads TIL and updates diary" do
        result = service.push_til(diary)

        expect(result[:success]).to be true
        expect(diary.reload.github_uploaded?).to be true
      end
    end

    context "when diary already uploaded" do
      before do
        diary.update!(github_uploaded: true)
      end

      it "returns failure message" do
        result = service.push_til(diary)

        expect(result[:success]).to be false
        expect(result[:message]).to include("すでにGitHubにアップロード済み")
      end
    end
  end

  describe "#reset_all_diaries_upload_status" do
    let!(:uploaded_diary) { create(:diary, :github_uploaded, user: user) }

    it "resets all diary upload statuses" do
      service.reset_all_diaries_upload_status

      expect(uploaded_diary.reload.github_uploaded?).to be false
    end
  end
end
