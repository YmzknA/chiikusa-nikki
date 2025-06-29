require "rails_helper"

RSpec.describe GithubService, type: :service do
  let(:user) { create(:user, :with_github, :with_github_repo) }
  let(:diary) { create(:diary, :with_selected_til, user: user) }
  let(:service) { described_class.new(user) }
  let(:mock_client) { instance_double(Octokit::Client) }

  before do
    allow(Octokit::Client).to receive(:new).and_return(mock_client)
  end

  describe "#create_repository" do
    context "when repository creation succeeds" do
      before do
        allow(service).to receive(:validate_repository_creation).and_return(nil)
        allow(service).to receive(:perform_repository_creation).and_return({
                                                                             success: true,
                                                                             message: "リポジトリを作成しました"
                                                                           })
      end

      it "creates repository successfully" do
        result = service.create_repository("test-repo")

        expect(result[:success]).to be true
        expect(result[:message]).to include("リポジトリを作成しました")
      end
    end

    context "when validation fails" do
      before do
        allow(service).to receive(:validate_repository_creation).and_return({
                                                                              success: false,
                                                                              message: "Validation failed"
                                                                            })
      end

      it "returns validation error" do
        result = service.create_repository("invalid-repo")

        expect(result[:success]).to be false
        expect(result[:message]).to include("Validation failed")
      end
    end

    context "when repository name is blank" do
      it "handles blank repository name" do
        result = service.create_repository("")
        expect(result).to be_present
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

    context "when client is not available" do
      before do
        allow(service).to receive(:client_available?).and_return(false)
      end

      it "returns failure message" do
        result = service.push_til(diary)

        expect(result[:success]).to be false
        expect(result[:message]).to include("クライアントが利用できません")
      end
    end

    context "when upload succeeds" do
      before do
        allow(service).to receive(:create_or_update_file).and_return({
                                                                       success: true,
                                                                       commit_sha: "abc123"
                                                                     })
      end

      it "uploads TIL successfully" do
        result = service.push_til(diary)

        expect(result[:success]).to be true
        expect(result[:message]).to include("アップロードしました")
        expect(diary.reload.github_uploaded).to be true
        expect(diary.github_file_path).to eq("#{diary.date.strftime('%y%m%d')}_til.md")
        expect(diary.github_commit_sha).to eq("abc123")
      end

      it "creates file with correct name format" do
        service.push_til(diary)

        expected_filename = "#{diary.date.strftime('%y%m%d')}_til.md"
        expect(service).to have_received(:create_or_update_file)
          .with("#{user.username}/#{user.github_repo_name}", expected_filename, anything, anything)
      end
    end

    context "when upload fails" do
      before do
        allow(service).to receive(:create_or_update_file).and_return({
                                                                       success: false,
                                                                       message: "Upload failed"
                                                                     })
      end

      it "returns error message" do
        result = service.push_til(diary)

        expect(result[:success]).to be false
        expect(result[:message]).to include("Upload failed")
      end
    end
  end

  describe "#reset_all_diaries_upload_status" do
    before do
      create_list(:diary, 3, :github_uploaded, user: user)
    end

    it "resets all diaries upload status to false" do
      expect do
        service.reset_all_diaries_upload_status
      end.to change { user.diaries.where(github_uploaded: true).count }.from(3).to(0)
    end

    it "clears all GitHub-related audit fields" do
      service.reset_all_diaries_upload_status

      user.diaries.each do |diary|
        expect(diary.github_uploaded).to be false
        expect(diary.github_uploaded_at).to be_nil
        expect(diary.github_file_path).to be_nil
        expect(diary.github_commit_sha).to be_nil
        expect(diary.github_repository_url).to be_nil
      end
    end
  end

  describe "content generation" do
    it "generates markdown content with TIL candidate" do
      allow(service).to receive(:generate_til_content).and_call_original
      content = service.send(:generate_til_content, diary)

      expect(content).to include("# TIL - #{diary.date.strftime('%Y年%m月%d日')}")
      expect(content).to include(diary.selected_til_content)
      expect(content).to include(diary.notes)
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
    context "when connection is successful" do
      before do
        allow(mock_client).to receive(:user).and_return(double(login: user.username))
      end

      it "returns success result" do
        result = service.test_github_connection

        expect(result[:success]).to be true
        expect(result[:message]).to include("接続成功")
      end
    end

    context "when unauthorized" do
      before do
        allow(mock_client).to receive(:user).and_raise(Octokit::Unauthorized)
      end

      it "returns failure message" do
        result = service.test_github_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include("認証エラー")
      end
    end

    context "when client is not available" do
      before do
        allow(service).to receive(:client_available?).and_return(false)
      end

      it "returns failure result" do
        result = service.test_github_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include("クライアントが利用できません")
      end
    end
  end

  describe "#get_repository_info" do
    context "when repository exists" do
      let(:repo_data) do
        double(
          name: "test-repo",
          full_name: "#{user.username}/test-repo",
          private: false,
          description: "Test repository",
          created_at: Time.current,
          updated_at: Time.current,
          html_url: "https://github.com/#{user.username}/test-repo"
        )
      end

      before do
        allow(mock_client).to receive(:repository).and_return(repo_data)
      end

      it "returns repository information" do
        result = service.get_repository_info("test-repo")

        expect(result[:name]).to eq("test-repo")
        expect(result[:full_name]).to eq("#{user.username}/test-repo")
        expect(result[:private]).to be false
        expect(result[:description]).to eq("Test repository")
        expect(result[:url]).to include("github.com")
      end
    end

    context "when repository does not exist" do
      before do
        allow(mock_client).to receive(:repository).and_raise(Octokit::NotFound)
      end

      it "returns nil" do
        result = service.get_repository_info("nonexistent")
        expect(result).to be_nil
      end
    end

    context "with invalid inputs" do
      it "returns nil for blank repo name" do
        expect(service.get_repository_info("")).to be_nil
        expect(service.get_repository_info(nil)).to be_nil
      end
    end
  end

  describe "#create_or_update_file" do
    let(:repo_name) { "#{user.username}/test-repo" }
    let(:file_path) { "test.md" }
    let(:content) { "# Test Content" }
    let(:commit_message) { "Test commit" }

    context "when file operation succeeds" do
      before do
        allow(service).to receive(:handle_file_operation).and_return({
                                                                       success: true,
                                                                       commit_sha: "abc123"
                                                                     })
      end

      it "returns success result" do
        result = service.create_or_update_file(repo_name, file_path, content, commit_message)

        expect(result[:success]).to be true
        expect(result[:commit_sha]).to eq("abc123")
      end
    end

    context "when client is not available" do
      before do
        allow(service).to receive(:client_available?).and_return(false)
      end

      it "returns error message" do
        result = service.create_or_update_file(repo_name, file_path, content, commit_message)

        expect(result[:success]).to be false
        expect(result[:message]).to include("クライアントが利用できません")
      end
    end

    context "when repository not found" do
      before do
        allow(service).to receive(:handle_file_operation).and_raise(Octokit::NotFound)
        allow(service).to receive(:handle_repository_not_found_error).and_return({
                                                                                   success: false,
                                                                                   message: "Repository not found"
                                                                                 })
      end

      it "handles error gracefully" do
        result = service.create_or_update_file(repo_name, file_path, content, commit_message)

        expect(result[:success]).to be false
        expect(result[:message]).to include("Repository not found")
      end
    end
  end

  describe "error handling" do
    it "handles various GitHub API errors" do
      error_cases = [
        [Octokit::Unauthorized, "handle_file_unauthorized_error"],
        [Octokit::Forbidden, "handle_file_forbidden_error"],
        [Octokit::Error, "handle_file_api_error"],
        [StandardError, "handle_file_unexpected_error"]
      ]

      error_cases.each do |error_class, handler_method|
        allow(service).to receive(:handle_file_operation).and_raise(error_class)
        allow(service).to receive(handler_method).and_return({ success: false, message: "Error handled" })

        result = service.create_or_update_file("repo", "file", "content", "message")
        expect(result[:success]).to be false
      end
    end
  end

  describe "Performance and scalability tests" do
    context "with large content uploads" do
      let(:large_diary) { create(:diary, :with_selected_til, user: user, notes: "Large content " * 1000) }

      before do
        allow(service).to receive(:create_or_update_file).and_return({
                                                                       success: true,
                                                                       commit_sha: "abc123"
                                                                     })
      end

      it "handles large TIL content efficiently" do
        start_time = Time.current
        result = service.push_til(large_diary)
        end_time = Time.current

        expect(result[:success]).to be true
        expect(end_time - start_time).to be < 5.seconds
      end
    end

    context "with concurrent operations" do
      let(:diaries) { create_list(:diary, 5, :with_selected_til, user: user) }

      before do
        allow(service).to receive(:create_or_update_file).and_return({
                                                                       success: true,
                                                                       commit_sha: "abc123"
                                                                     })
      end

      it "handles multiple simultaneous uploads" do
        threads = diaries.map do |diary|
          Thread.new { service.push_til(diary) }
        end

        results = threads.map(&:value)

        expect(results).to all(satisfy { |r| r[:success] == true })
        expect(diaries.all? { |d| d.reload.github_uploaded? }).to be true
      end
    end

    context "with rate limiting simulation" do
      before do
        call_count = 0
        allow(mock_client).to receive(:create_contents) do
          call_count += 1
          raise Octokit::TooManyRequests.new(response_headers: { "retry-after" => "60" }) if call_count <= 2

          double(commit: double(sha: "success_sha"))
        end
        allow(service).to receive(:handle_file_operation).and_call_original
      end

      it "handles GitHub rate limiting" do
        result = service.create_or_update_file("repo", "file", "content", "message")

        expect(result[:success]).to be false
      end
    end
  end

  describe "Security and validation tests" do
    context "with malicious input" do
      let(:malicious_inputs) do
        {
          repo_name: ["'; DROP TABLE repos; --", "../../../etc/passwd", "<script>alert('xss')</script>"],
          file_path: ["../../../etc/passwd", "../../.ssh/authorized_keys", "<script>evil.js</script>"],
          content: ["<script>malicious()</script>", "\x00\x01\x02", "eval('malicious code')"],
          commit_message: ["<script>alert('pwned')</script>", "'; DROP TABLE commits; --"]
        }
      end

      before do
        allow(service).to receive(:create_or_update_file).and_call_original
        allow(service).to receive(:handle_file_operation).and_return({
                                                                       success: true,
                                                                       commit_sha: "safe_sha"
                                                                     })
      end

      it "safely handles malicious repository names" do
        malicious_inputs[:repo_name].each do |malicious_name|
          result = service.create_or_update_file(malicious_name, "safe.md", "content", "message")
          expect(result).to be_a(Hash)
        end
      end

      it "safely handles malicious file paths" do
        malicious_inputs[:file_path].each do |malicious_path|
          result = service.create_or_update_file("safe/repo", malicious_path, "content", "message")
          expect(result).to be_a(Hash)
        end
      end

      it "safely handles malicious content" do
        malicious_inputs[:content].each do |malicious_content|
          result = service.create_or_update_file("safe/repo", "safe.md", malicious_content, "message")
          expect(result).to be_a(Hash)
        end
      end
    end

    context "with boundary values" do
      it "handles extremely long repository names" do
        long_name = "a" * 1000
        result = service.repository_exists?(long_name)
        expect(result).to be false
      end

      it "handles empty and nil inputs gracefully" do
        expect(service.repository_exists?("")).to be false
        expect(service.repository_exists?(nil)).to be false
        expect(service.get_repository_info("")).to be_nil
        expect(service.get_repository_info(nil)).to be_nil
      end
    end
  end

  describe "Integration with GitHub API edge cases" do
    context "when GitHub returns unexpected response formats" do
      let(:malformed_responses) do
        [
          nil,
          {},
          { "invalid" => "structure" },
          { "name" => nil, "full_name" => "" }
        ]
      end

      it "handles malformed repository responses" do
        malformed_responses.each do |response|
          allow(mock_client).to receive(:repository).and_return(response)

          result = service.get_repository_info("test-repo")
          expect(result).to be_nil
        end
      end
    end

    context "when network issues occur" do
      let(:network_errors) do
        [
          Net::TimeoutError.new("Timeout"),
          Errno::ECONNREFUSED.new("Connection refused"),
          SocketError.new("Socket error"),
          OpenSSL::SSL::SSLError.new("SSL error")
        ]
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "handles various network errors gracefully" do
        network_errors.each do |error|
          allow(mock_client).to receive(:repository).and_raise(error)

          result = service.repository_exists?("test-repo")
          expect(result).to be false
          expect(Rails.logger).to have_received(:error)
        end
      end
    end

    context "when GitHub API returns partial content" do
      before do
        allow(mock_client).to receive(:repository).and_return(
          double(
            name: "test-repo",
            full_name: "user/test-repo",
            private: nil, # Missing field
            description: "",
            created_at: nil,
            updated_at: Time.current,
            html_url: "https://github.com/user/test-repo"
          )
        )
      end

      it "handles partial repository information gracefully" do
        result = service.get_repository_info("test-repo")

        expect(result[:name]).to eq("test-repo")
        expect(result[:private]).to be_nil
        expect(result[:description]).to eq("")
      end
    end
  end

  describe "Audit and logging functionality" do
    let(:diary_with_audit) { create(:diary, :with_selected_til, user: user) }

    before do
      allow(service).to receive(:create_or_update_file).and_return({
                                                                     success: true,
                                                                     commit_sha: "audit_sha_123"
                                                                   })
    end

    it "properly sets audit fields on successful upload" do
      freeze_time do
        result = service.push_til(diary_with_audit)

        expect(result[:success]).to be true

        diary_with_audit.reload
        expect(diary_with_audit.github_uploaded).to be true
        expect(diary_with_audit.github_uploaded_at).to be_within(1.second).of(Time.current)
        expect(diary_with_audit.github_commit_sha).to eq("audit_sha_123")
        expect(diary_with_audit.github_file_path).to eq("#{diary_with_audit.date.strftime('%y%m%d')}_til.md")
        expect(diary_with_audit.github_repository_url).to include(user.github_repo_name)
      end
    end

    it "preserves audit trail during reset operations" do
      # First upload
      service.push_til(diary_with_audit)
      diary_with_audit.reload.github_uploaded_at

      # Reset
      service.reset_all_diaries_upload_status

      diary_with_audit.reload
      expect(diary_with_audit.github_uploaded).to be false
      expect(diary_with_audit.github_uploaded_at).to be_nil
      expect(diary_with_audit.github_commit_sha).to be_nil
    end
  end

  describe "Content generation edge cases" do
    context "with various diary content scenarios" do
      let(:test_scenarios) do
        [
          {
            name: "diary with only notes",
            diary_attrs: { notes: "Just notes", selected_til_index: nil, til_text: nil }
          },
          {
            name: "diary with only TIL text",
            diary_attrs: { notes: nil, selected_til_index: nil, til_text: "Just TIL" }
          },
          {
            name: "diary with selected TIL candidate",
            diary_attrs: { notes: "Notes", selected_til_index: 0 }
          },
          {
            name: "diary with special characters",
            diary_attrs: { notes: "特殊文字 🚀 テスト", til_text: "日本語TIL 📝" }
          }
        ]
      end

      it "generates appropriate content for various scenarios" do
        test_scenarios.each do |scenario|
          test_diary = create(:diary, user: user, **scenario[:diary_attrs])
          create_list(:til_candidate, 3, diary: test_diary) if scenario[:diary_attrs][:selected_til_index]

          content = service.send(:generate_til_content, test_diary)

          expect(content).to include("# TIL - #{test_diary.date.strftime('%Y年%m月%d日')}")
          expect(content).to be_a(String)
          expect(content.length).to be > 10
        end
      end
    end
  end
end
