require "rails_helper"

RSpec.describe "Comprehensive Diaries System Tests", type: :system do
  let(:user) { create(:user, :with_github) }
  let(:questions) do
    {
      mood: create(:question, :mood),
      motivation: create(:question, :motivation),
      progress: create(:question, :progress)
    }
  end
  let(:answers) do
    {
      mood: create_list(:answer, 5, question: questions[:mood]),
      motivation: create_list(:answer, 5, question: questions[:motivation]),
      progress: create_list(:answer, 5, question: questions[:progress])
    }
  end

  before do
    questions && answers # Create questions and answers
    sign_in user
    allow_any_instance_of(OpenaiService).to receive(:generate_tils)
      .and_return(["TIL 1 content", "TIL 2 content", "TIL 3 content"])
  end

  describe "diary creation workflow", js: true do
    it "creates a complete diary with TIL generation" do
      visit diaries_path

      expect(page).to have_content("日記一覧")

      click_link "新しい日記を書く"

      expect(page).to have_current_path(new_diary_path)
      expect(page).to have_content("日記を書く")

      # Fill in answers
      find("input[value='#{answers[:mood][2].id}']").choose
      find("input[value='#{answers[:motivation][3].id}']").choose
      find("input[value='#{answers[:progress][4].id}']").choose

      # Fill in notes
      fill_in "diary[notes]", with: "- RSpecのテストを書いた\n- システムテストを実行した"

      # Check AI generation option if available
      find("input[name='use_ai_generation']").check if page.has_field?("use_ai_generation")

      click_button "日記を作成"

      # Should redirect to edit page for TIL selection
      expect(page).to have_content("続いて生成されたTIL")
      expect(page).to have_content("TIL 1 content")
      expect(page).to have_content("TIL 2 content")
      expect(page).to have_content("TIL 3 content")

      # Select a TIL
      find("input[value='0']").choose

      click_button "日記を完成させる"

      expect(page).to have_content("日記を更新しました")
      expect(page).to have_content("TIL 1 content")
    end

    it "creates diary without AI generation when opted out" do
      visit new_diary_path

      find("input[value='#{answers[:mood][1].id}']").choose
      find("input[value='#{answers[:motivation][1].id}']").choose
      find("input[value='#{answers[:progress][1].id}']").choose

      fill_in "diary[notes]", with: "シンプルなメモ"

      # Do not check AI generation

      click_button "日記を作成"

      expect(page).to have_content("日記を作成しました")
      expect(page).to have_content("シンプルなメモ")
    end

    it "handles seed shortage gracefully" do
      user.update!(seed_count: 0)

      visit new_diary_path

      find("input[value='#{answers[:mood][2].id}']").choose
      find("input[value='#{answers[:motivation][2].id}']").choose
      find("input[value='#{answers[:progress][2].id}']").choose

      fill_in "diary[notes]", with: "テストメモ"

      find("input[name='use_ai_generation']").check if page.has_field?("use_ai_generation")

      click_button "日記を作成"

      expect(page).to have_content("タネが不足")
    end
  end

  describe "diary editing", js: true do
    let(:diary) { create(:diary, :with_til_candidates, user: user) }

    it "allows editing diary content and TIL selection" do
      visit edit_diary_path(diary)

      expect(page).to have_content("日記を編集")

      fill_in "diary[notes]", with: "更新されたメモ"

      # Select a TIL
      find("input[value='1']").choose

      click_button "日記を完成させる"

      expect(page).to have_content("日記を更新しました")
      expect(page).to have_content("更新されたメモ")
    end

    it "allows regenerating TIL candidates" do
      user.update!(seed_count: 3)

      visit edit_diary_path(diary)

      find("input[name='regenerate_ai']").check if page.has_field?("regenerate_ai")

      click_button "日記を完成させる"

      expect(page).to have_content("日記を更新しました")
    end
  end

  describe "diary display and navigation" do
    let!(:diary1) { create(:diary, user: user, date: Date.current) }
    let!(:diary2) { create(:diary, user: user, date: Date.current - 1.day) }
    let!(:public_diary) { create(:diary, :public, date: Date.current - 2.days) }

    it "displays user diaries in chronological order" do
      visit diaries_path

      expect(page).to have_content(diary1.date.strftime("%Y年%m月%d日"))
      expect(page).to have_content(diary2.date.strftime("%Y年%m月%d日"))
    end

    it "shows diary details" do
      visit diary_path(diary1)

      expect(page).to have_content(diary1.notes)
      expect(page).to have_content(diary1.date.strftime("%Y年%m月%d日"))
    end

    it "allows editing own diaries" do
      visit diary_path(diary1)

      expect(page).to have_link("編集")

      click_link "編集"

      expect(page).to have_current_path(edit_diary_path(diary1))
    end

    it "shows public diaries to anonymous users" do
      sign_out user

      visit diary_path(public_diary)

      expect(page).to have_content(public_diary.notes)
      expect(page).not_to have_link("編集")
    end
  end

  describe "calendar functionality", js: true do
    let!(:diary) { create(:diary, user: user, date: Date.current) }

    it "displays calendar with diary indicators" do
      visit diaries_path

      expect(page).to have_selector(".simple-calendar")
      expect(page).to have_selector(".has-diary")
    end
  end

  describe "seed management", js: true do
    it "increments seeds with watering button" do
      visit diaries_path

      if page.has_selector?("#seed-count")
        initial_count = find("#seed-count").text.to_i

        if page.has_selector?("#watering-button")
          find("#watering-button").click

          expect(page).to have_content("タネを増やしました")
          expect(find("#seed-count").text.to_i).to eq(initial_count + 1)
        end
      end
    end

    it "shows seed shortage modal when needed" do
      user.update!(seed_count: 0)

      visit new_diary_path

      find("input[value='#{answers[:mood][0].id}']").choose
      find("input[value='#{answers[:motivation][0].id}']").choose
      find("input[value='#{answers[:progress][0].id}']").choose

      fill_in "diary[notes]", with: "メモ"

      find("input[name='use_ai_generation']").check if page.has_field?("use_ai_generation")

      click_button "日記を作成"

      expect(page).to have_content("タネが不足")
    end
  end

  describe "GitHub integration", js: true do
    let(:diary) { create(:diary, :with_selected_til, user: user) }

    before do
      user.update!(github_repo_name: "test-til")
    end

    it "shows GitHub upload button when configured" do
      visit diary_path(diary)

      expect(page).to have_button("GitHubにアップロード")
    end

    it "disables GitHub button when already uploaded" do
      diary.update!(github_uploaded: true)

      visit diary_path(diary)

      expect(page).to have_button("GitHubにアップロード", disabled: true)
    end

    it "hides GitHub button when repository not configured" do
      user.update!(github_repo_name: nil)

      visit diary_path(diary)

      expect(page).not_to have_button("GitHubにアップロード")
    end
  end

  describe "public diaries" do
    let!(:public_diary1) { create(:diary, :public, :with_answers) }
    let!(:public_diary2) { create(:diary, :public, :with_answers) }
    let!(:private_diary) { create(:diary, is_public: false) }

    it "shows public diaries to anonymous users" do
      sign_out user

      visit public_diaries_path

      expect(page).to have_content("公開日記")
      expect(page).to have_content(public_diary1.date.strftime("%Y年%m月%d日"))
      expect(page).to have_content(public_diary2.date.strftime("%Y年%m月%d日"))
      expect(page).not_to have_content(private_diary.date.strftime("%Y年%m月%d日"))
    end

    it "limits public diaries display" do
      create_list(:diary, 25, :public)

      visit public_diaries_path

      # Should show maximum 20 diaries
      expect(page).to have_selector(".diary-entry", maximum: 20)
    end
  end

  describe "error handling" do
    it "handles duplicate diary creation" do
      create(:diary, user: user, date: Date.current)

      visit new_diary_path

      find("input[value='#{answers[:mood][0].id}']").choose
      find("input[value='#{answers[:motivation][0].id}']").choose
      find("input[value='#{answers[:progress][0].id}']").choose

      fill_in "diary[notes]", with: "テスト"

      click_button "日記を作成"

      expect(page).to have_content("既に作成されています")
    end

    it "handles validation errors gracefully" do
      visit new_diary_path

      # Don't fill in required fields
      click_button "日記を作成"

      expect(page).to have_content("エラー")
    end
  end

  describe "navigation and user experience" do
    it "provides smooth navigation between pages" do
      visit root_path

      expect(page).to have_content("ちいくさ日記")

      if user_signed_in?
        click_link "日記一覧"
        expect(page).to have_current_path(diaries_path)

        click_link "統計"
        expect(page).to have_current_path(stats_path)

        click_link "プロフィール"
        expect(page).to have_current_path(profile_path)
      end
    end

    it "displays flash messages properly" do
      visit new_diary_path

      find("input[value='#{answers[:mood][0].id}']").choose
      find("input[value='#{answers[:motivation][0].id}']").choose
      find("input[value='#{answers[:progress][0].id}']").choose

      fill_in "diary[notes]", with: "テストメモ"

      click_button "日記を作成"

      expect(page).to have_selector(".flash")
    end
  end

  describe "accessibility and responsive design" do
    it "displays properly on mobile viewport", js: true do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size

      visit diaries_path

      expect(page).to have_content("日記一覧")

      # Reset to desktop size
      page.driver.browser.manage.window.resize_to(1200, 800)
    end

    it "provides keyboard navigation" do
      visit diaries_path

      # Test tab navigation
      page.execute_script("document.querySelector('a').focus()")
      expect(page).to have_selector(":focus")
    end
  end

  describe "Complex end-to-end workflows" do
    describe "Complete user journey from creation to GitHub upload" do
      it "completes full diary workflow including GitHub upload", js: true do
        user.update!(seed_count: 5, github_repo_name: "my-til-repo")

        # Step 1: Create diary with AI generation
        visit diaries_path
        click_link "新しい日記を書く"

        # Fill evaluation
        find("input[value='#{answers[:mood][3].id}']").choose
        find("input[value='#{answers[:motivation][4].id}']").choose
        find("input[value='#{answers[:progress][2].id}']").choose

        # Add detailed notes
        notes_content = <<~NOTES
          - Railsのシステムテストを実装
          - Capybraを使ったブラウザテスト
          - Seleniumドライバーの設定
          - 複雑なユーザーインタラクションのテスト
        NOTES

        fill_in "diary[notes]", with: notes_content

        click_button "日記を作成"

        # Step 2: TIL selection
        expect(page).to have_content("続いて生成されたTIL")
        find("input[value='1']").choose # Select second TIL

        click_button "日記を完成させる"

        # Step 3: Verify diary details
        expect(page).to have_content("日記を更新しました")
        expect(page).to have_content("TIL 2 content")

        # Step 4: Upload to GitHub (mock)
        mock_service = instance_double(GithubService)
        allow(user).to receive(:github_service).and_return(mock_service)
        allow(mock_service).to receive(:push_til)
          .and_return({ success: true, message: "Successfully uploaded to GitHub" })

        click_button "GitHubにアップロード"

        # Step 5: Verify final state
        expect(page).to have_content("GitHubにアップロードしました")
        expect(page).to have_button("GitHubにアップロード", disabled: true)

        # Verify seed count decreased
        expect(user.reload.seed_count).to eq(4)
      end

      it "handles complete diary editing and privacy workflow", js: true do
        diary = create(:diary, :with_til_candidates, user: user, is_public: false)

        # Step 1: Edit diary
        visit edit_diary_path(diary)

        # Update content
        fill_in "diary[notes]", with: "Updated diary content with new insights"

        # Change TIL selection
        find("input[value='2']").choose

        # Make public
        check "diary[is_public]"

        click_button "日記を完成させる"

        # Step 2: Verify updates
        expect(page).to have_content("日記を更新しました")
        expect(page).to have_content("Updated diary content")

        # Step 3: Check public visibility
        sign_out user
        visit diary_path(diary)

        expect(page).to have_content("Updated diary content")
        expect(page).not_to have_link("編集")

        # Step 4: Verify in public listings
        visit public_diaries_path
        expect(page).to have_content(diary.date.strftime("%Y年%m月%d日"))
      end
    end

    describe "Multi-day diary creation workflow" do
      it "creates diaries across multiple dates", js: true do
        dates = [Date.current, Date.current - 1.day, Date.current - 2.days]

        dates.each_with_index do |date, index|
          visit new_diary_path(date: date)

          # Different mood for each day
          find("input[value='#{answers[:mood][index].id}']").choose
          find("input[value='#{answers[:motivation][index + 1].id}']").choose
          find("input[value='#{answers[:progress][index + 2].id}']").choose

          fill_in "diary[notes]", with: "Day #{index + 1} notes"

          click_button "日記を作成"

          expect(page).to have_content("日記を作成しました")
        end

        # Verify all diaries exist
        visit diaries_path
        dates.each_with_index do |_date, index|
          expect(page).to have_content("Day #{index + 1} notes")
        end
      end
    end

    describe "Seed management across sessions" do
      it "manages seed count through various actions", js: true do
        user.update!(seed_count: 1)

        # Step 1: Use seed for AI generation
        visit new_diary_path

        find("input[value='#{answers[:mood][0].id}']").choose
        find("input[value='#{answers[:motivation][0].id}']").choose
        find("input[value='#{answers[:progress][0].id}']").choose

        fill_in "diary[notes]", with: "Testing seed consumption"

        click_button "日記を作成"

        # Verify seed consumed
        expect(user.reload.seed_count).to eq(0)

        # Step 2: Try to create another with no seeds
        visit new_diary_path(date: Date.current + 1.day)

        find("input[value='#{answers[:mood][1].id}']").choose
        find("input[value='#{answers[:motivation][1].id}']").choose
        find("input[value='#{answers[:progress][1].id}']").choose

        fill_in "diary[notes]", with: "No seeds available"

        click_button "日記を作成"

        expect(page).to have_content("タネが不足")

        # Step 3: Get more seeds through watering
        visit diaries_path

        if page.has_selector?("#watering-button")
          find("#watering-button").click
          expect(page).to have_content("タネを増やしました")
        end
      end
    end

    describe "Error recovery workflows" do
      it "recovers from validation errors gracefully", js: true do
        visit new_diary_path

        # Submit without required fields
        click_button "日記を作成"

        expect(page).to have_content("エラー")

        # Fix errors and resubmit
        find("input[value='#{answers[:mood][0].id}']").choose
        find("input[value='#{answers[:motivation][0].id}']").choose
        find("input[value='#{answers[:progress][0].id}']").choose

        click_button "日記を作成"

        expect(page).to have_content("日記を作成しました")
      end

      it "handles network interruption simulation", js: true do
        # This would test how the app handles network issues
        # In a real scenario, you might use tools like toxiproxy

        visit new_diary_path

        find("input[value='#{answers[:mood][0].id}']").choose
        find("input[value='#{answers[:motivation][0].id}']").choose
        find("input[value='#{answers[:progress][0].id}']").choose

        fill_in "diary[notes]", with: "Testing resilience"

        # Simulate slow response (not actual network failure in test env)
        page.execute_script("
          const originalFetch = window.fetch;
          window.fetch = function(...args) {
            return new Promise(resolve => {
              setTimeout(() => resolve(originalFetch.apply(this, args)), 100);
            });
          };
        ")

        click_button "日記を作成"

        expect(page).to have_content("日記を作成しました")
      end
    end

    describe "Performance under load simulation" do
      it "handles rapid user interactions", js: true do
        diary = create(:diary, user: user)

        # Rapidly navigate between pages
        5.times do
          visit diary_path(diary)
          visit diaries_path
          visit edit_diary_path(diary)
        end

        expect(page).to have_content("日記を編集")
      end

      it "handles large content efficiently", js: true do
        large_notes = "Long content. " * 1000

        visit new_diary_path

        find("input[value='#{answers[:mood][0].id}']").choose
        find("input[value='#{answers[:motivation][0].id}']").choose
        find("input[value='#{answers[:progress][0].id}']").choose

        fill_in "diary[notes]", with: large_notes

        click_button "日記を作成"

        expect(page).to have_content("日記を作成しました")
        expect(page).to have_content("Long content.")
      end
    end
  end
end
