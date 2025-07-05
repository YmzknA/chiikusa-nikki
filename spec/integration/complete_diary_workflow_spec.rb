require "rails_helper"

RSpec.describe "Complete Diary Workflow Integration", type: :request do
  let(:user) { create(:user, :with_github, seed_count: 5) }
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
  let(:mock_openai_service) { instance_double(OpenaiService::Base) }
  let(:mock_github_service) { instance_double(GithubService) }

  before do
    questions && answers
    sign_in user

    # Mock external API calls with WebMock
    stub_request(:post, /api\.openai\.com/)
      .to_return(
        status: 200,
        body: {
          choices: [
            { message: { content: "TIL 1\nTIL 2\nTIL 3" } }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    allow(user).to receive(:github_service).and_return(mock_github_service)
    allow_any_instance_of(DiaryService).to receive(:create_openai_service).and_return(mock_openai_service)
  end

  describe "end-to-end diary creation and publication workflow" do
    it "creates diary -> generates TIL -> shares on X" do
      # Step 1: Create diary with AI generation
      allow(mock_openai_service).to receive(:generate_tils)
        .and_return(["TIL 1", "TIL 2", "TIL 3"])

      diary_params = {
        diary: {
          date: Date.current,
          notes: "Today I learned RSpec testing",
          is_public: false
        },
        diary_answers: {
          questions[:mood].identifier => answers[:mood][3].id,
          questions[:motivation].identifier => answers[:motivation][4].id,
          questions[:progress].identifier => answers[:progress][2].id
        },
        use_ai_generation: "1"
      }

      post diaries_path, params: diary_params

      expect(response).to redirect_to(select_til_diary_path(Diary.last))
      expect(flash[:notice]).to include("続いて生成されたTIL")

      created_diary = Diary.last
      expect(created_diary.notes).to eq("Today I learned RSpec testing")
      expect(created_diary.til_candidates.count).to eq(3)
      expect(created_diary.diary_answers.count).to eq(3)
      expect(user.reload.seed_count).to eq(4) # Decreased by 1

      # Step 2: Select TIL and complete diary
      put diary_path(created_diary), params: {
        diary: {
          selected_til_index: 1,
          is_public: true
        }
      }

      expect(response).to redirect_to(diary_path(created_diary))
      expect(flash[:notice]).to include("日記を更新しました")

      created_diary.reload
      expect(created_diary.selected_til_index).to eq(1)
      expect(created_diary.is_public).to be true

      # Step 3: Share on X and get seed reward
      post share_on_x_diaries_path, params: { diary_id: created_diary.id }

      expect(response).to redirect_to(diary_path(created_diary))
      expect(user.reload.seed_count).to eq(5) # Should remain at max 5
    end

    it "handles workflow with insufficient seeds" do
      user.update!(seed_count: 0)

      diary_params = {
        diary: {
          date: Date.current,
          notes: "Testing with no seeds",
          is_public: false
        },
        diary_answers: {
          questions[:mood].identifier => answers[:mood][1].id
        },
        use_ai_generation: "1"
      }

      post diaries_path, params: diary_params

      expect(response).to redirect_to(Diary.last)
      expect(flash[:notice]).to include("タネが不足")

      created_diary = Diary.last
      expect(created_diary.til_candidates.count).to eq(0)
      expect(user.reload.seed_count).to eq(0) # Unchanged
    end

    it "completes workflow without AI generation" do
      diary_params = {
        diary: {
          date: Date.current,
          notes: "Simple diary without AI",
          is_public: true
        },
        diary_answers: {
          questions[:mood].identifier => answers[:mood][2].id
        }
        # No use_ai_generation parameter
      }

      post diaries_path, params: diary_params

      expect(response).to redirect_to(Diary.last)
      expect(flash[:notice]).to eq("日記を作成しました")

      created_diary = Diary.last
      expect(created_diary.til_candidates.count).to eq(0)
      expect(user.reload.seed_count).to eq(5) # Unchanged
    end
  end

  describe "diary editing workflow" do
    let(:diary) { create(:diary, user: user) }

    it "edits existing diary" do
      put diary_path(diary), params: {
        diary: {
          notes: "Updated notes with new content",
          selected_til_index: 1
        }
      }

      expect(response).to redirect_to(diary_path(diary))
      expect(flash[:notice]).to include("日記を更新しました")

      diary.reload
      expect(diary.notes).to eq("Updated notes with new content")
      expect(diary.selected_til_index).to eq(1)
    end
  end

  describe "seed management workflow" do
    it "handles seed increment requests" do
      post increment_seed_diaries_path

      expect(response).to redirect_to(diaries_path)
      expect(flash[:notice]).to be_present
    end

    it "handles share requests" do
      diary = create(:diary, user: user)

      post share_on_x_diaries_path, params: { diary_id: diary.id }

      expect(response).to redirect_to(diary_path(diary))
    end

    it "respects maximum seed count limit" do
      user.update!(seed_count: 5)

      post increment_seed_diaries_path

      expect(user.reload.seed_count).to eq(5) # Should not exceed maximum
    end
  end

  describe "GitHub integration workflow" do
    let(:diary) { create(:diary, user: user) }

    it "prevents upload without configuration" do
      post upload_to_github_diary_path(diary)

      expect(response).to redirect_to(diary_path(diary))
      expect(flash[:alert]).to include("アップロードできません")
    end

    it "prevents duplicate uploads" do
      diary.update!(github_uploaded: true)

      post upload_to_github_diary_path(diary)

      expect(response).to redirect_to(diary_path(diary))
      expect(flash[:alert]).to include("アップロードできません")
    end
  end

  describe "search and navigation workflow" do
    let!(:diary1) { create(:diary, user: user, date: Date.current) }
    let!(:diary2) { create(:diary, user: user, date: Date.current - 1.day) }

    it "searches diary by date" do
      get search_by_date_diaries_path,
          params: { date: Date.current.to_s },
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["diary_id"]).to eq(diary1.id)
    end

    it "handles search for non-existent date" do
      get search_by_date_diaries_path,
          params: { date: (Date.current + 1.year).to_s },
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["diary_id"]).to be_nil
    end

    it "validates date format in search" do
      get search_by_date_diaries_path,
          params: { date: "invalid-date" },
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to include("Invalid date format")
    end
  end

  describe "public diary workflow" do
    let!(:public_diary) { create(:diary, :public, :with_answers) }
    let!(:private_diary) { create(:diary, is_public: false) }

    it "displays public diaries to anonymous users" do
      sign_out user

      get public_diaries_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(public_diary.date.strftime("%Y/%m/%d"))
    end

    it "limits public diary display to 20 entries" do
      create_list(:diary, 25, :public)

      get public_diaries_path

      expect(response).to have_http_status(:success)
      expect(assigns(:diaries).count).to eq(20)
    end

    it "allows anonymous access to individual public diaries" do
      sign_out user

      get diary_path(public_diary)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(public_diary.notes)
    end
  end

  describe "error handling and validation workflow" do
    it "handles duplicate diary creation gracefully" do
      create(:diary, user: user, date: Date.current)

      diary_params = {
        diary: {
          date: Date.current,
          notes: "Duplicate diary attempt"
        },
        diary_answers: {
          questions[:mood].identifier => answers[:mood][0].id
        }
      }

      post diaries_path, params: diary_params

      expect(response).to render_template(:new)
      expect(response.body).to include("の日記は既に作成されています")
    end

    it "validates required diary fields" do
      diary_params = {
        diary: {
          date: nil,
          notes: ""
        }
      }

      post diaries_path, params: diary_params

      expect(response).to render_template(:new)
      expect(response.body).to include("error") # Should show validation errors
    end

    it "handles invalid diary ID gracefully" do
      get diary_path(999_999)

      expect(response).to redirect_to(diaries_path)
      expect(flash[:alert]).to include("見つかりません")
    end
  end

  describe "authentication and authorization workflow" do
    it "redirects unauthenticated users to login" do
      sign_out user

      get diaries_path

      expect(response).to redirect_to(root_path)
    end

    it "prevents users from accessing other users' diaries" do
      other_user = create(:user, :with_github)
      other_diary = create(:diary, user: other_user)

      get diary_path(other_diary)

      expect(response).to redirect_to(diaries_path)
      expect(flash[:alert]).to include("見つかりません")
    end

    it "allows authenticated users to edit their own diaries" do
      diary = create(:diary, user: user)

      get edit_diary_path(diary)

      expect(response).to have_http_status(:success)
      expect(assigns(:diary)).to eq(diary)
    end
  end

  describe "statistics and analytics workflow" do
    before do
      create_list(:diary, 5, :with_answers, user: user)
    end

    it "generates comprehensive statistics" do
      get stats_path

      expect(response).to have_http_status(:success)
      expect(assigns(:chart_builder)).to be_a(ChartBuilderService)
      expect(assigns(:daily_trends_chart)).to be_present
      expect(assigns(:monthly_posts_chart)).to be_present
    end

    it "handles different chart parameters" do
      get stats_path, params: {
        view_type: "monthly",
        target_month: "2024-01",
        weekday_months: 3
      }

      expect(response).to have_http_status(:success)
      expect(assigns(:view_type)).to eq("monthly")
      expect(assigns(:target_month)).to eq("2024-01")
      expect(assigns(:weekday_months)).to eq(3)
    end
  end
end
