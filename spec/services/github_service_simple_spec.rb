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

      it "creates file in YYYY/MM directory format" do
        diary = create(:diary, :with_selected_til, user: user, date: Date.new(2025, 1, 22))
        allow(service).to receive(:create_or_update_file)
          .and_return({ success: true, commit_sha: "abc123" })

        result = service.push_til(diary)

        expect(result[:success]).to be true
        expect(diary.reload.github_file_path).to eq("2025/01/250122_til.md")
      end

      it "organizes files by year and month" do
        diary_jan = create(:diary, :with_selected_til, user: user, date: Date.new(2025, 1, 15))
        diary_feb = create(:diary, :with_selected_til, user: user, date: Date.new(2025, 2, 20))
        diary_next_year = create(:diary, :with_selected_til, user: user, date: Date.new(2026, 1, 10))

        allow(service).to receive(:create_or_update_file)
          .and_return({ success: true, commit_sha: "abc123" })

        service.push_til(diary_jan)
        service.push_til(diary_feb)
        service.push_til(diary_next_year)

        expect(diary_jan.reload.github_file_path).to eq("2025/01/250115_til.md")
        expect(diary_feb.reload.github_file_path).to eq("2025/02/250220_til.md")
        expect(diary_next_year.reload.github_file_path).to eq("2026/01/260110_til.md")
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
