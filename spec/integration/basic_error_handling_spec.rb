require "rails_helper"

RSpec.describe "Basic Error Handling", type: :request do
  let(:user) { create(:user, :with_github) }

  before do
    sign_in user
  end

  describe "External service failures" do
    context "when OpenAI service fails" do
      before do
        # Mock OpenAI client to raise error
        mock_client = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_raise(StandardError, "OpenAI API failure")
      end

      it "handles OpenAI failure gracefully during diary creation" do
        user.update!(seed_count: 3)

        post diaries_path, params: {
          diary: {
            notes: "Today I learned Rails"
          },
          answers: { "1" => "1" }
        }

        expect(response).to redirect_to(new_diary_path)
        expect(flash[:alert]).to be_present
        expect(user.reload.seed_count).to eq(3) # Should not decrement on failure
      end
    end

    context "when GitHub service fails" do
      let(:diary) { create(:diary, :with_selected_til, user: user) }

      before do
        user.update!(github_repo_name: "test-repo")
        # Mock GitHub client to raise error
        mock_client = instance_double(Octokit::Client)
        allow(Octokit::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_contents).and_raise(StandardError, "GitHub API failure")
        allow(mock_client).to receive(:contents).and_raise(Octokit::NotFound)
      end

      it "handles GitHub failure gracefully during upload" do
        post upload_to_github_diary_path(diary)

        expect(response).to redirect_to(diary_path(diary))
        expect(flash[:alert]).to be_present
        expect(diary.reload.github_uploaded?).to be false
      end
    end
  end

  describe "Basic validation errors" do
    it "handles missing diary notes" do
      post diaries_path, params: {
        diary: { notes: "" },
        answers: { "1" => "1" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
