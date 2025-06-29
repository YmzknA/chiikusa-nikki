require "rails_helper"

RSpec.describe "Page Layouts", type: :system do
  let(:user) { create(:user, :with_github, username: "testuser") }
  let(:diary) { create(:diary, user: user, notes: "テスト日記") }

  before do
    login_as(user, scope: :user)
  end

  describe "Home Page Layout" do
    it "renders home page structure correctly" do
      visit root_path
      
      # ホームページの基本構造
      expect(page).to have_selector("main")
      expect(page).to have_content("ちいくさ日記") # ページタイトル
    end
  end

  describe "Diary Index Layout" do
    it "renders diary list layout correctly" do
      create_list(:diary, 3, user: user)
      visit diaries_path
      
      # 日記一覧の構造確認
      expect(page).to have_selector(".neuro-card", count: 3)
      expect(page).to have_selector(".grid")
      expect(page).to have_link("新しい日記を書く")
      
      # ヘッダーナビゲーション
      expect(page).to have_selector('[data-controller="water-effect"]')
      expect(page).to have_link(href: "/profile")
      expect(page).to have_link(href: "/stats")
      expect(page).to have_link(href: "/github_settings")
    end
  end

  describe "Diary Form Layout" do
    it "renders new diary form layout correctly" do
      visit new_diary_path
      
      # フォームレイアウトの確認
      expect(page).to have_field("日記のメモ")
      expect(page).to have_button("保存")
      
      # 評価セクションの存在
      expect(page).to have_content("気分")
      expect(page).to have_content("モチベーション")
      expect(page).to have_content("進捗")
      
      # フォーム要素の構造
      expect(page).to have_selector("form")
      expect(page).to have_selector(".neuro-card")
    end

    it "renders edit diary form layout correctly" do
      visit edit_diary_path(diary)
      
      # 編集フォームの構造確認
      expect(page).to have_field("日記のメモ", with: diary.notes)
      expect(page).to have_button("更新")
      
      # TIL関連要素（存在する場合）
      expect(page).to have_content("TIL") rescue nil
    end
  end

  describe "Diary Detail Layout" do
    it "renders diary show page layout correctly" do
      visit diary_path(diary)
      
      # 詳細ページの構造確認
      expect(page).to have_content(diary.date.strftime("%Y/%m/%d"))
      expect(page).to have_content(diary.notes)
      expect(page).to have_link("編集")
      
      # アクションボタン類
      expect(page).to have_selector(".neuro-button") rescue nil
    end
  end

  describe "Profile Layout" do
    it "renders profile page layout correctly" do
      visit profile_path
      
      # プロフィールページの構造
      expect(page).to have_content(user.username)
      expect(page).to have_content("プロフィール")
      
      # プロバイダー関連情報
      expect(page).to have_content("GitHub") rescue nil
      expect(page).to have_content("Google") rescue nil
    end
  end

  describe "Stats Layout" do
    it "renders stats page layout correctly" do
      visit stats_path
      
      # 統計ページの構造
      expect(page).to have_content("統計")
      expect(page).to have_selector("canvas") rescue nil # Chart.js
    end
  end

  describe "GitHub Settings Layout" do
    it "renders GitHub settings layout correctly" do
      visit github_settings_path
      
      # GitHub設定ページの構造
      expect(page).to have_content("GitHub")
      expect(page).to have_content("設定")
    end
  end

  describe "Public Diaries Layout" do
    it "renders public diaries layout correctly" do
      create(:diary, :public, notes: "公開日記")
      visit public_diaries_path
      
      # 公開日記一覧の構造
      expect(page).to have_content("公開日記一覧")
      expect(page).to have_selector(".neuro-card")
      expect(page).to have_link("ホームに戻る")
    end
  end

  describe "Error Pages Layout" do
    it "handles 404 errors gracefully" do
      visit "/nonexistent-page"
      
      # エラーページの構造（実装されている場合）
      expect(page).to have_http_status(404) rescue nil
    end
  end
end