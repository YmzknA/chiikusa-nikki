require "rails_helper"

RSpec.describe GithubService, type: :service do
  let(:user) do
    User.create!(
      email: "test@example.com",
      password: "password",
      github_id: "123456",
      username: "testuser",
      access_token: "test_token",
      github_repo_name: "test-til"
    )
  end

  let(:diary) do
    user.diaries.create!(
      date: Date.current,
      notes: "Test notes",
      selected_til_index: 0
    )
  end

  let(:til_candidate) do
    diary.til_candidates.create!(
      content: "Today I learned about RSpec testing",
      index: 0
    )
  end

  let(:service) { described_class.new(user) }
  let(:mock_client) { instance_double(Octokit::Client) }

  before do
    allow(Octokit::Client).to receive(:new).and_return(mock_client)
  end

  describe "#create_repository" do
    context "when repository creation succeeds" do
      before do
        allow(mock_client).to receive(:create_repository).and_return(true)
        allow(mock_client).to receive(:create_contents).and_return(true)
      end

      it "creates repository successfully" do
        result = service.create_repository("test-repo")

        expect(result[:success]).to be true
        expect(result[:message]).to include("test-repo")
        expect(mock_client).to have_received(:create_repository).with("test-repo", private: true,
                                                                                   description: "Programming Diary TIL Repository")
      end
    end

    context "when repository name already exists" do
      before do
        allow(mock_client).to receive(:create_repository).and_raise(Octokit::UnprocessableEntity.new)
      end

      it "returns failure message" do
        result = service.create_repository("existing-repo")

        expect(result[:success]).to be false
        expect(result[:message]).to include("既に存在")
      end
    end

    context "when repository name is blank" do
      it "returns failure message" do
        result = service.create_repository("")

        expect(result[:success]).to be false
        expect(result[:message]).to include("指定されていません")
      end
    end
  end

  describe "#repository_exists?" do
    context "when repository exists" do
      before do
        allow(mock_client).to receive(:repository).and_return(true)
      end

      it "returns true" do
        expect(service.repository_exists?("test-repo")).to be true
      end
    end

    context "when repository does not exist" do
      before do
        allow(mock_client).to receive(:repository).and_raise(Octokit::NotFound.new)
      end

      it "returns false" do
        expect(service.repository_exists?("nonexistent-repo")).to be false
      end
    end

    context "when repository name is blank" do
      it "returns false" do
        expect(service.repository_exists?("")).to be false
        expect(service.repository_exists?(nil)).to be false
      end
    end
  end

  describe "#push_til" do
    before do
      til_candidate # Create the TIL candidate
    end

    context "when user has no repository configured" do
      before do
        user.update!(github_repo_name: nil)
      end

      it "returns failure message" do
        result = service.push_til(diary)

        expect(result[:success]).to be false
        expect(result[:message]).to include("設定されていません")
      end
    end

    context "when diary is already uploaded" do
      before do
        diary.update!(github_uploaded: true)
      end

      it "returns failure message" do
        result = service.push_til(diary)

        expect(result[:success]).to be false
        expect(result[:message]).to include("アップロード済み")
      end
    end

    context "when upload succeeds" do
      before do
        allow(mock_client).to receive(:create_contents).and_return(true)
      end

      it "uploads TIL successfully" do
        expect do
          result = service.push_til(diary)
          expect(result[:success]).to be true
        end.to change { diary.reload.github_uploaded }.from(false).to(true)
      end

      it "creates file with correct name format" do
        service.push_til(diary)

        expected_filename = "#{diary.date.strftime('%y%m%d')}_til.md"
        expect(mock_client).to have_received(:create_contents).with(
          "testuser/test-til",
          expected_filename,
          "Add TIL for #{diary.date}",
          anything
        )
      end
    end

    context "when repository not found" do
      before do
        allow(mock_client).to receive(:create_contents).and_raise(Octokit::NotFound.new)
      end

      it "returns repository not found error" do
        result = service.push_til(diary)

        expect(result[:success]).to be false
        expect(result[:message]).to include("見つかりません")
      end
    end
  end

  describe "#reset_all_diaries_upload_status" do
    before do
      diary.update!(github_uploaded: true)
      user.diaries.create!(date: Date.yesterday, github_uploaded: true)
    end

    it "resets all diaries upload status to false" do
      expect do
        service.reset_all_diaries_upload_status
      end.to change { user.diaries.where(github_uploaded: true).count }.from(2).to(0)
    end
  end

  describe "#generate_til_content" do
    before do
      til_candidate
    end

    it "generates markdown content with TIL candidate" do
      content = service.send(:generate_til_content, diary)

      expect(content).to include("# TIL - #{diary.date.strftime('%Y年%m月%d日')}")
      expect(content).to include("Today I learned about RSpec testing")
      expect(content).to include("Test notes")
      expect(content).to include("*Generated by Programming Diary*")
    end

    context "when no TIL candidate is selected" do
      before do
        diary.update!(selected_til_index: nil)
      end

      it "uses til_text or empty string" do
        diary.update!(til_text: "Fallback TIL content")
        content = service.send(:generate_til_content, diary)

        expect(content).to include("Fallback TIL content")
      end
    end
  end

  describe "#test_github_connection" do
    let(:mock_user_info) do
      double(
        login: "testuser",
        name: "Test User",
        public_repos: 5,
        total_private_repos: 3
      )
    end

    context "when connection is successful" do
      before do
        allow(mock_client).to receive(:user).and_return(mock_user_info)
      end

      it "returns success with user info" do
        result = service.test_github_connection

        expect(result[:success]).to be true
        expect(result[:user_info][:login]).to eq("testuser")
        expect(result[:user_info][:public_repos]).to eq(5)
      end
    end

    context "when unauthorized" do
      before do
        allow(mock_client).to receive(:user).and_raise(Octokit::Unauthorized.new)
      end

      it "returns failure message" do
        result = service.test_github_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include("認証に失敗")
      end
    end
  end

  describe "#valid_repository_name?" do
    it "validates repository names correctly" do
      expect(service.send(:valid_repository_name?, "valid-repo")).to be true
      expect(service.send(:valid_repository_name?, "valid_repo")).to be true
      expect(service.send(:valid_repository_name?, "valid.repo")).to be true
      expect(service.send(:valid_repository_name?, "ValidRepo123")).to be true

      expect(service.send(:valid_repository_name?, "")).to be false
      expect(service.send(:valid_repository_name?, ".invalid")).to be false
      expect(service.send(:valid_repository_name?, "invalid.")).to be false
      expect(service.send(:valid_repository_name?, "invalid@repo")).to be false
      expect(service.send(:valid_repository_name?, "a" * 101)).to be false
    end
  end

  describe "#create_or_update_file" do
    let(:repo_name) { "testuser/test-repo" }
    let(:file_path) { "test.md" }
    let(:content) { "# Test Content" }
    let(:commit_message) { "Test commit" }

    context "when file does not exist" do
      before do
        allow(mock_client).to receive(:contents).and_raise(Octokit::NotFound.new)
        allow(mock_client).to receive(:create_contents).and_return(true)
      end

      it "creates new file" do
        result = service.create_or_update_file(repo_name, file_path, content, commit_message)

        expect(result[:success]).to be true
        expect(result[:action]).to eq("created")
        expect(mock_client).to have_received(:create_contents)
      end
    end

    context "when file exists" do
      let(:existing_file) { double(sha: "abc123") }

      before do
        allow(mock_client).to receive(:contents).and_return(existing_file)
        allow(mock_client).to receive(:update_contents).and_return(true)
      end

      it "updates existing file" do
        result = service.create_or_update_file(repo_name, file_path, content, commit_message)

        expect(result[:success]).to be true
        expect(result[:action]).to eq("updated")
        expect(mock_client).to have_received(:update_contents)
      end
    end
  end
end
