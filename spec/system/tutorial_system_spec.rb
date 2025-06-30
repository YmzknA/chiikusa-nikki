require 'rails_helper'

RSpec.describe "Tutorial System", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1400])
  end

  describe "New user registration flow" do
    context "when user completes username setup" do
      let(:new_user) { create(:user, username: nil) }
      
      before do
        sign_in new_user
      end

      it "redirects to tutorial page after setting username" do
        visit setup_username_path
        
        fill_in "user_username", with: "test_user"
        click_button "始める"
        
        expect(current_path).to eq(tutorial_path)
        expect(page).to have_text("ユーザー名を設定しました！まずは使い方を確認しましょう")
      end

      it "displays comprehensive tutorial after username setup" do
        visit setup_username_path
        
        fill_in "user_username", with: "test_user"
        click_button "始める"
        
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
        
        within(".sidebar") do
          click_link "使い方"
        end
        
        expect(current_path).to eq(tutorial_path)
        expect(page).to have_text("ちいくさ日記の使い方")
      end
    end

    context "from profile page" do
      it "can access tutorial from profile page" do
        visit profile_path
        
        click_link "使い方"
        
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
        expect(page).to have_button("閉じる")
      end

      it "can navigate back using close button" do
        visit tutorial_path
        
        click_button "閉じる"
        
        # Should navigate back to previous page or diary index
        expect(current_path).to eq(diaries_path)
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
      expect(page).to have_selector("h2", count: 5) # Each step should have h2
    end

    it "tutorial modal has proper focus management" do
      user.update(first_login: true)
      visit diaries_path
      
      # Focus should be managed when modal opens
      expect(page).to have_selector("#tutorial-modal")
    end
  end
end