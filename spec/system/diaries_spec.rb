require "rails_helper"

RSpec.describe "Diaries", :js, type: :system do
  before do
    OmniAuth.config.mock_auth[:github] = nil
    Rails.application.env_config["omniauth.auth"] = github_mock
  end

  let(:github_mock) do
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "12345",
      info: {
        nickname: "testuser",
        email: "test@example.com"
      },
      credentials: {
        token: "test_token"
      }
    )
  end

  it "creates a new diary" do
    visit root_path
    click_button "GitHubでログイン"

    expect(page).to have_content("ログインしました")
    expect(page).to have_current_path(diaries_path)

    click_link "新しい日記を書く"

    choose "diary_answers_mood_1"
    choose "diary_answers_motivation_1"
    choose "diary_answers_progress_1"
    fill_in "箇条書きで入力...", with: "- RSpecのテストを書いた
- システムテストを実行した"
    click_button "日記を作成"

    expect(page).to have_content("日記を作成しました。TILを選択してください。")

    choose(page.all("input[type=radio]").first.id)
    click_button "日記を完成させる"

    expect(page).to have_content("日記を更新しました")
    expect(page).to have_selector(".simple-calendar")
  end
end
