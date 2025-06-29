require "rails_helper"

RSpec.describe "Basic Diaries UI", type: :system do
  let(:user) { create(:user, :with_github) }
  let(:question) { create(:question, :mood) }
  let(:answer) { create(:answer, :level_four, question: question) }

  before do
    # Setup basic test data
    question
    answer

    # Mock external services for system tests
    stub_request(:post, /api\.openai\.com/).to_return(
      status: 200,
      body: { choices: [{ message: { content: "Test TIL content" } }] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    login_as(user, scope: :user)
  end

  describe "Basic navigation" do
    it "can access diary pages without errors" do
      visit diaries_path
      expect(page).to have_http_status(200)

      visit new_diary_path
      expect(page).to have_http_status(200)
    end
  end

  describe "Basic page functionality" do
    it "renders pages successfully" do
      visit diaries_path
      expect(page.status_code).to eq(200)
    end
  end
end
