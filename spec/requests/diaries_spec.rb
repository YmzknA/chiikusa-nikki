require 'rails_helper'

RSpec.describe "Diaries", type: :request do
  let(:user) { User.create!(github_id: "12345", username: "testuser", access_token: "test_token") }

  before do
    OmniAuth.config.mock_auth[:github] = nil
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(OpenaiService).to receive(:generate_til).and_return(["- TIL 1", "- TIL 2", "- TIL 3"])
  end

  describe "GET /diaries" do
    it "returns http success" do
      get diaries_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /diaries" do
    let(:question) { Question.create!(identifier: :mood, label: "今日の気分") }
    let(:answer) { question.answers.create!(level: 1, emoji: "😞") }

    it "creates a new diary and redirects" do
      diary_params = { date: Time.zone.today, notes: "- Test", is_public: true }
      diary_answers_params = { mood: answer.id }

      post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(edit_diary_path(Diary.last))
    end
  end
end
