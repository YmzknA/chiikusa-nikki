require "rails_helper"

RSpec.describe "Basic Diaries UI", type: :system do
  let(:user) { create(:user, :with_github) }
  let(:question) { create(:question, :mood) }
  let(:answer) { create(:answer, :level_4, question: question) }

  before do
    # Setup basic test data
    question
    answer
    
    # Mock external services for system tests
    stub_request(:post, /api\.openai\.com/).to_return(
      status: 200,
      body: { choices: [{ message: { content: "Test TIL content" } }] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    
    login_as(user, scope: :user)
  end

  describe "Diary creation flow" do
    it "allows user to create a diary with basic UI interactions", js: true do
      visit new_diary_path

      # Fill in basic diary form
      fill_in "日記のメモ", with: "今日はRailsの勉強をした"
      
      # Select answers (simplified)
      first(".answer-option").click
      
      click_button "日記を作成"

      # Verify basic creation
      expect(page).to have_content("日記を作成しました")
      expect(page).to have_content("今日はRailsの勉強をした")
    end
  end

  describe "Diary list view" do
    let!(:diary) { create(:diary, user: user) }

    it "displays diary list with basic information" do
      visit diaries_path

      expect(page).to have_content("日記一覧")
      expect(page).to have_content(diary.date.strftime("%Y年%m月%d日"))
    end
  end

  describe "Seed count display" do
    it "shows current seed count" do
      user.update!(seed_count: 3)
      visit diaries_path

      expect(page).to have_content("3")
    end
  end
end