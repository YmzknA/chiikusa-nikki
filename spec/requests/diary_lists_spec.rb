require "rails_helper"

RSpec.describe "DiaryLists", type: :request do
  let(:user) { create(:user, :with_github) }
  let!(:diaries) { create_list(:diary, 5, user: user) }
  let(:question) { create(:question, :mood) }
  let(:answer) { create(:answer, :level_four, question: question) }

  before do
    sign_in user
  end

  describe "GET /diary_lists" do
    it "returns http success" do
      get diary_lists_path
      expect(response).to have_http_status(:success)
    end

    it "displays user's diaries in paginated list" do
      get diary_lists_path
      expect(response).to have_http_status(:success)
      expect(assigns(:diaries)).to be_present
      expect(assigns(:pagy)).to be_present
    end

    it "filters diaries by month" do
      diary_this_month = create(:diary, user: user, date: Date.current)
      diary_last_month = create(:diary, user: user, date: Date.current - 1.month)

      current_month = Date.current.strftime("%Y-%m")
      get diary_lists_path, params: { month: current_month }

      expect(assigns(:diaries)).to include(diary_this_month)
      expect(assigns(:diaries)).not_to include(diary_last_month)
    end

    it "shows all diaries when month filter is 'all'" do
      get diary_lists_path, params: { month: "all" }
      expect(assigns(:diaries).count).to eq(diaries.count)
    end

    it "sets up reaction data for public diaries" do
      public_diary = create(:diary, user: user, is_public: true)
      create(:reaction, diary: public_diary)

      get diary_lists_path
      expect(assigns(:reactions_summary_data)).to be_present
    end

    it "requires authentication" do
      sign_out user
      get diary_lists_path
      expect(response).to redirect_to(root_path)
    end

    it "includes necessary associations" do
      diary = create(:diary, user: user)
      create(:til_candidate, diary: diary)
      create(:diary_answer, diary: diary, answer: answer)

      get diary_lists_path

      # Ensure includes are working properly
      expect { assigns(:diaries).first.til_candidates.to_a }.not_to exceed_query_limit(0)
      expect { assigns(:diaries).first.diary_answers.first.answer }.not_to exceed_query_limit(0)
    end

    it "orders diaries by date desc and created_at desc" do
      older_diary = create(:diary, user: user, date: Date.current - 1.day, created_at: 1.hour.ago)
      newer_diary = create(:diary, user: user, date: Date.current, created_at: Time.current)

      get diary_lists_path
      diary_ids = assigns(:diaries).map(&:id)

      expect(diary_ids.index(newer_diary.id)).to be < diary_ids.index(older_diary.id)
    end
  end
end
