require "rails_helper"

RSpec.describe "UI Elements Regression", type: :system do
  let(:user) { create(:user, :with_github, username: "testuser") }
  let(:diary) { create(:diary, user: user, notes: "テスト日記の内容です") }

  before do
    sign_in user
  end

  describe "Core UI Components" do
    it "renders header navigation correctly" do
      visit diaries_path
      
      # ヘッダー要素の存在確認
      expect(page).to have_selector("main")
      expect(page).to have_link(href: "/profile")
      expect(page).to have_link(href: "/stats") 
      expect(page).to have_link(href: "/github_settings")
      expect(page).to have_link(href: "/diaries/new")
      
      # ウォータリングボタンの存在
      expect(page).to have_selector('[data-controller="water-effect"]')
      expect(page).to have_selector(".water-button")
    end

    it "renders diary cards with proper structure" do
      diary # Create diary
      visit diaries_path
      
      # 日記カードの基本構造
      expect(page).to have_selector(".neuro-card")
      expect(page).to have_content(diary.date.strftime("%Y/%m/%d"))
      expect(page).to have_content("今日のメモ")
      expect(page).to have_content(diary.notes)
      expect(page).to have_link("詳細を見る")
    end

    it "renders form elements correctly" do
      visit new_diary_path
      
      # フォーム要素の存在確認
      expect(page).to have_field("日記のメモ")
      expect(page).to have_button("保存")
      
      # 評価セクションの存在（気分、モチベーション、進捗）
      expect(page).to have_content("気分")
      expect(page).to have_content("モチベーション") 
      expect(page).to have_content("進捗")
    end

    it "renders buttons with correct styling classes" do
      visit diaries_path
      
      # ボタンのクラス確認
      expect(page).to have_selector(".neuro-button")
      expect(page).to have_selector(".neuro-button-secondary")
      expect(page).to have_selector(".neuro-card")
    end
  end

  describe "Responsive Design Elements" do
    it "renders mobile-friendly layout" do
      visit diaries_path
      
      # モバイル対応の確認
      expect(page).to have_selector(".container")
      expect(page).to have_selector(".grid")
    end
  end

  describe "Theme and Styling" do
    it "applies correct theme classes" do
      visit diaries_path
      
      # テーマクラスの確認
      expect(page).to have_selector('body[data-theme="lemonade"]')
      expect(page).to have_selector(".lemonade-background")
      expect(page).to have_selector(".m-plus-1p-regular")
    end
  end
end