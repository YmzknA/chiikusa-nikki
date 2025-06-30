require "rails_helper"

RSpec.describe "Tutorial System", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:headless_chrome)
  end

  describe "New user registration flow" do
    context "when user completes username setup" do
      let(:new_user) { create(:user, username: User::DEFAULT_USERNAME) }

      before do
        sign_in new_user
      end

      it "redirects to tutorial page after setting username" do
        visit setup_username_path

        fill_in "user_username", with: "test_user"
        click_button "草を生やし始める"

        # リダイレクトを待つ
        expect(page).to have_text("ちいくさ日記の使い方")

        expect(current_path).to eq(tutorial_path)
        expect(page).to have_text("ユーザー名を設定しました！まずは使い方を確認しましょう")
      end

      it "displays comprehensive tutorial after username setup" do
        visit setup_username_path

        fill_in "user_username", with: "test_user"
        click_button "草を生やし始める"

        # リダイレクトを待つ
        expect(page).to have_text("ちいくさ日記の使い方")
        expect(page).to have_text("日記の作り方")
        expect(page).to have_text("AIでTILを自動生成")
        expect(page).to have_text("GitHub連携で草を生やそう")
        expect(page).to have_text("学習の振り返り")
        expect(page).to have_text("みんなの頑張りを見る")
      end
    end
  end

  describe "Tutorial page navigation" do
    before do
      sign_in user
    end

    context "from sidebar" do
      it "can access tutorial from sidebar" do
        visit diaries_path

        # PC版のサイドバーまたはモバイル版のナビゲーションから使い方リンクをクリック
        click_link "使い方", match: :first

        # チュートリアルページへの移動を待つ
        expect(page).to have_text("ちいくさ日記の使い方")
        expect(current_path).to eq(tutorial_path)
        expect(page).to have_text("ちいくさ日記の使い方")
      end
    end

    context "from profile page" do
      it "can access tutorial from profile page" do
        visit profile_path

        click_link "使い方", match: :first

        # チュートリアルページへの移動を待つ
        expect(page).to have_text("ちいくさ日記の使い方")
        expect(current_path).to eq(tutorial_path)
        expect(page).to have_text("ちいくさ日記の使い方")
      end
    end

    context "tutorial page content" do
      it "displays comprehensive tutorial content" do
        visit tutorial_path

        expect(page).to have_text("ちいくさ日記の使い方")
        expect(page).to have_text("日記の作り方")
        expect(page).to have_text("AIでTILを自動生成")
        expect(page).to have_text("GitHub連携で草を生やそう")
        expect(page).to have_text("学習の振り返り")
        expect(page).to have_text("みんなの頑張りを見る")
      end

      it "includes actionable links" do
        visit tutorial_path

        expect(page).to have_link("日記を書く", href: new_diary_path)
        # チュートリアルページには閉じるボタンはない
      end

      it "can navigate to diary creation" do
        visit tutorial_path

        click_link "日記を書く"

        # 日記作成ページへの移動を待つ
        expect(page).to have_text("今日やったこと・感じたこと")
        expect(current_path).to eq(new_diary_path)
      end
    end
  end

  describe "Tutorial accessibility" do
    before do
      sign_in user
    end

    it "tutorial page has proper headings structure" do
      visit tutorial_path

      expect(page).to have_selector("h1", text: "ちいくさ日記の使い方")
      expect(page).to have_selector("h2", count: 6) # Each step plus summary should have h2
    end

    it "tutorial page maintains accessibility" do
      visit tutorial_path

      # Basic accessibility check - page should have proper structure
      expect(page).to have_selector("main")
      expect(page).to have_selector("h1")
    end
  end
end
