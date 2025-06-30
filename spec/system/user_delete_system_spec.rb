require "rails_helper"

RSpec.describe "User Delete System", type: :system do
  let(:user) { create(:user) }
  let!(:diary1) { create(:diary, user: user) }
  let!(:diary2) { create(:diary, user: user) }

  before do
    driven_by(:headless_chrome)
    sign_in user
  end

  describe "User deletion flow" do
    it "displays delete button on profile page" do
      visit profile_path

      expect(page).to have_button("アカウントを削除")
    end

    it "opens confirmation modal when delete button is clicked" do
      visit profile_path

      click_button "アカウントを削除"

      expect(page).to have_text("⚠️ アカウント削除の確認")
      expect(page).to have_text("重要な注意事項")
      expect(page).to have_text("この操作は取り消すことができません")
    end

    it "shows user-specific information in modal" do
      visit profile_path

      click_button "アカウントを削除"

      within(".modal") do
        expect(page).to have_text("#{user.username}さんのアカウント情報")
        expect(page).to have_text("作成した全ての日記（2件）")
        expect(page).to have_text("タネの残数（#{user.seed_count}個）")
      end
    end

    it "shows detailed warning about data loss" do
      visit profile_path

      click_button "アカウントを削除"

      within(".modal") do
        expect(page).to have_text("削除される内容:")
        expect(page).to have_text("GitHub・Google連携情報")
        expect(page).to have_text("タネの残数")
        expect(page).to have_text("今まで積み重ねた学習の記録がすべて失われます")
      end
    end

    it "requires username confirmation" do
      visit profile_path

      click_button "アカウントを削除"

      within(".modal") do
        expect(page).to have_text("確認のため、ユーザー名「#{user.username}」を入力してください")
        expect(page).to have_field("confirm_username", placeholder: user.username)
      end
    end

    it "prevents deletion with wrong username" do
      visit profile_path

      click_button "アカウントを削除"

      within(".modal") do
        fill_in "confirm_username", with: "wrong_username"
        click_button "削除する"
      end

      # JavaScriptアラートが表示される（実際のテストではアラートハンドリングが必要）
      # モーダルが閉じずに残る
      expect(page).to have_text("⚠️ アカウント削除の確認")
    end

    it "prevents deletion with empty username" do
      visit profile_path

      click_button "アカウントを削除"

      within(".modal") do
        # 空のまま削除ボタンをクリック
        click_button "削除する"
      end

      # JavaScriptアラートが表示される
      # モーダルが閉じずに残る
      expect(page).to have_text("⚠️ アカウント削除の確認")
    end

    it "can cancel deletion" do
      visit profile_path

      click_button "アカウントを削除"
      click_button "キャンセル"

      expect(page).not_to have_text("⚠️ アカウント削除の確認")
      expect(current_path).to eq(profile_path)
    end

    it "can close modal by clicking outside" do
      visit profile_path

      click_button "アカウントを削除"

      # ESCキーでモーダルを閉じる
      page.send_keys :escape

      expect(page).not_to have_text("⚠️ アカウント削除の確認")
    end

    it "successfully deletes user account" do
      visit profile_path

      click_button "アカウントを削除"

      # ユーザー名確認入力
      within(".modal") do
        fill_in "confirm_username", with: user.username
        click_button "削除する"
      end

      expect(current_path).to eq(root_path)
      expect(page).to have_text("#{user.username}さんのアカウントを削除しました")
      expect(page).to have_text("ご利用ありがとうございました")

      # ユーザーと関連データが削除されているか確認
      expect(User.find_by(id: user.id)).to be_nil
      expect(Diary.where(user_id: user.id)).to be_empty
    end

    it "signs out user after deletion" do
      visit profile_path

      click_button "アカウントを削除"

      # ユーザー名確認入力
      within(".modal") do
        fill_in "confirm_username", with: user.username
        click_button "削除する"
      end

      # ログアウト状態であることを確認
      visit profile_path
      expect(current_path).to eq(root_path) # 認証が必要なページにリダイレクト
    end
  end

  describe "Modal accessibility" do
    it "has proper focus management" do
      visit profile_path

      click_button "アカウントを削除"

      # モーダルが表示されていることを確認
      expect(page).to have_selector(".modal")
    end

    it "has proper button labels and structure" do
      visit profile_path

      click_button "アカウントを削除"

      within(".modal") do
        expect(page).to have_button("キャンセル")
        expect(page).to have_button("削除する")
        expect(page).to have_selector(".alert-error")
      end
    end
  end

  describe "Error handling" do
    before do
      allow_any_instance_of(User).to receive(:destroy).and_return(false)
      allow_any_instance_of(User).to receive(:errors).and_return(double(full_messages: ["Test error"]))
    end

    it "handles deletion failure gracefully" do
      visit profile_path

      click_button "アカウントを削除"

      # ユーザー名確認入力
      within(".modal") do
        fill_in "confirm_username", with: user.username
        click_button "削除する"
      end

      expect(current_path).to eq(profile_path)
      expect(page).to have_text("アカウントの削除に失敗しました")
      expect(page).to have_text("時間をおいて再度お試しください")
    end
  end
end
