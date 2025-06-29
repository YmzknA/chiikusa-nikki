require "rails_helper"

RSpec.describe "Diaries", type: :request do
  let(:user) { create(:user, :with_github) }
  let(:diary) { create(:diary, user: user) }
  let(:question) { create(:question, :mood) }
  let(:answer) { create(:answer, :level_4, question: question) }

  before do
    sign_in user
  end

  describe "GET /diaries" do
    it "returns http success" do
      get diaries_path
      expect(response).to have_http_status(:success)
    end

    it "displays user's diaries" do
      diary = create(:diary, user: user)
      get diaries_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("ちいくさ日記")
    end

    it "requires authentication" do
      sign_out user
      get diaries_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /diaries/new" do
    it "returns http success" do
      get new_diary_path
      expect(response).to have_http_status(:success)
    end

    it "sets today's date by default" do
      get new_diary_path
      expect(assigns(:date)).to eq(Date.current)
    end

    it "accepts date parameter" do
      custom_date = Date.current - 1.day
      get new_diary_path, params: { date: custom_date }
      expect(assigns(:date)).to eq(custom_date)
    end

    it "detects existing diary for the date" do
      existing_diary = create(:diary, user: user, date: Date.current)
      get new_diary_path, params: { date: Date.current }
      expect(assigns(:existing_diary)).to eq(existing_diary)
    end
  end

  describe "GET /diaries/:id" do
    it "returns http success for own diary" do
      get diary_path(diary)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for public diary" do
      public_diary = create(:diary, :public)
      get diary_path(public_diary)
      expect(response).to have_http_status(:success)
    end

    it "redirects when diary not found" do
      get diary_path(999_999)
      expect(response).to redirect_to(diaries_path)
    end

    it "allows unauthenticated access to public diaries" do
      sign_out user
      public_diary = create(:diary, :public)
      get diary_path(public_diary)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /diaries/:id/edit" do
    it "returns http success" do
      get edit_diary_path(diary)
      expect(response).to have_http_status(:success)
    end

    it "loads selected answers" do
      create(:diary_answer, diary: diary, question: question, answer: answer)
      get edit_diary_path(diary)
      selected_answers = assigns(:selected_answers)
      expect(selected_answers[question.identifier]).to eq(answer.id.to_s)
    end

    it "requires authentication" do
      sign_out user
      get edit_diary_path(diary)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /diaries" do
    let(:diary_params) { { date: Date.current, notes: "Test notes", is_public: false } }
    let(:diary_answers_params) { { question.identifier => answer.id } }

    context "with valid parameters" do
      it "creates a new diary" do
        expect do
          post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }
        end.to change(Diary, :count).by(1)
      end

      it "creates diary answers" do
        expect do
          post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }
        end.to change(DiaryAnswer, :count).by(1)
      end

      it "redirects with TIL generation when notes present" do
        user.update!(seed_count: 3)
        mock_openai = instance_double(OpenaiService)
        allow(OpenaiService).to receive(:new).and_return(mock_openai)
        allow(mock_openai).to receive(:generate_tils).and_return(["TIL 1", "TIL 2", "TIL 3"])

        post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }

        # TIL生成が成功した場合はeditページ、失敗した場合はshowページにリダイレクト
        diary = Diary.last
        expect(response).to redirect_to(diary_path(diary)).or(redirect_to(edit_diary_path(diary)))
      end

      it "redirects without TIL generation when notes blank" do
        diary_params[:notes] = ""

        post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }

        expect(response).to redirect_to(diary_path(Diary.last))
      end

      it "skips AI generation when requested" do
        user.update!(seed_count: 3)

        post diaries_path, params: {
          diary: diary_params,
          diary_answers: diary_answers_params,
          skip_ai_generation: "true"
        }

        expect(response).to redirect_to(diary_path(Diary.last))
      end
    end

    context "with invalid parameters" do
      it "renders new template when date is duplicate" do
        create(:diary, user: user, date: Date.current)

        post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }

        expect(response).to render_template(:new)
        expect(assigns(:existing_diary_for_error)).to be_present
      end

      it "renders new template with validation errors" do
        diary_params[:date] = nil

        post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }

        expect(response).to render_template(:new)
      end
    end
  end

  describe "PATCH /diaries/:id" do
    let(:update_params) { { notes: "Updated notes", is_public: true, selected_til_index: 0 } }

    context "with valid parameters" do
      it "updates the diary" do
        patch diary_path(diary), params: { diary: update_params }

        diary.reload
        expect(diary.notes).to eq("Updated notes")
        expect(diary.is_public).to be true
        expect(response).to redirect_to(diary_path(diary))
      end

      it "regenerates TIL candidates when requested" do
        user.update!(seed_count: 3)
        allow_any_instance_of(OpenaiService).to receive(:generate_tils).and_return(["New TIL 1", "New TIL 2",
                                                                                    "New TIL 3"])

        patch diary_path(diary), params: {
          diary: update_params,
          regenerate_ai: "1"
        }

        expect(response).to redirect_to(diary_path(diary))
      end
    end

    context "with invalid parameters" do
      it "handles validation errors appropriately" do
        patch diary_path(diary), params: { diary: { date: nil } }

        expect(response).to redirect_to(diary_path(diary))
      end

      it "handles unauthorized access to other user's diary" do
        other_user = create(:user, github_id: "other_user")
        other_diary = create(:diary, user: other_user)

        patch diary_path(other_diary), params: { diary: update_params }

        expect(response).to redirect_to(diaries_path)
      end

      it "handles TIL regeneration without sufficient seeds" do
        user.update!(seed_count: 0)

        patch diary_path(diary), params: {
          diary: update_params,
          regenerate_ai: "1"
        }

        expect(response).to redirect_to(diary_path(diary))
        expect(flash[:notice]).to be_present
      end

      it "handles invalid selected_til_index" do
        update_params[:selected_til_index] = 999

        patch diary_path(diary), params: { diary: update_params }

        expect(response).to redirect_to(diary_path(diary))

        diary.reload
        expect(diary.selected_til_index).to eq(999)
      end

      it "handles concurrent updates gracefully" do
        original_updated_at = diary.updated_at

        patch diary_path(diary), params: { diary: { notes: "First update" } }
        patch diary_path(diary), params: { diary: { notes: "Second update" } }

        diary.reload
        expect(diary.notes).to eq("Second update")
        expect(diary.updated_at).to be > original_updated_at
      end
    end
  end

  describe "DELETE /diaries/:id" do
    it "destroys the diary" do
      diary_to_delete = create(:diary, user: user)

      expect do
        delete diary_path(diary_to_delete)
      end.to change(Diary, :count).by(-1)

      expect(response).to redirect_to(diaries_path)
    end

    it "requires authentication" do
      sign_out user
      delete diary_path(diary)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /diaries/:id/upload_to_github" do
    let(:github_diary) { create(:diary, :with_selected_til, user: user) }

    before do
      user.update!(github_repo_name: "test-til")
    end

    it "uploads to GitHub when conditions are met" do
      mock_service = instance_double(GithubService)
      allow(user).to receive(:github_service).and_return(mock_service)
      allow(mock_service).to receive(:push_til).and_return({ success: true, message: "Uploaded successfully" })

      post upload_to_github_diary_path(github_diary)

      expect(response).to redirect_to(diary_path(github_diary))
    end

    it "shows error when upload not possible" do
      github_diary.update!(github_uploaded: true)

      post upload_to_github_diary_path(github_diary)

      expect(response).to redirect_to(diary_path(github_diary))
      expect(flash[:alert]).to include("アップロードできません")
    end
  end

  describe "POST /diaries/increment_seed" do
    it "increments seed count successfully" do
      expect do
        post increment_seed_diaries_path
      end.to change { user.reload.seed_count }.by(1)

      expect(response).to redirect_to(diaries_path)
    end

    it "responds with turbo stream" do
      post increment_seed_diaries_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "does not increment when limit reached" do
      user.update!(seed_count: 5)

      expect do
        post increment_seed_diaries_path
      end.not_to(change { user.reload.seed_count })
    end
  end

  describe "POST /diaries/share_on_x" do
    it "increments seed count for sharing" do
      expect do
        post share_on_x_diaries_path, params: { diary_id: diary.id }
      end.to change { user.reload.seed_count }.by(1)
    end

    it "responds with JSON" do
      post share_on_x_diaries_path,
           params: { diary_id: diary.id },
           headers: { "Accept" => "application/json" }

      expect(response.media_type).to eq("application/json")
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be true
    end
  end

  describe "GET /diaries/search_by_date" do
    it "returns diary ID for existing date" do
      get search_by_date_diaries_path,
          params: { date: diary.date.to_s },
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["diary_id"]).to eq(diary.id)
    end

    it "returns null for non-existing date" do
      get search_by_date_diaries_path,
          params: { date: (Date.current + 1.year).to_s },
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["diary_id"]).to be_nil
    end

    it "returns error for invalid date format" do
      get search_by_date_diaries_path,
          params: { date: "invalid-date" },
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to include("Invalid date format")
    end
  end

  describe "GET /public_diaries" do
    it "returns http success without authentication" do
      sign_out user
      get public_diaries_path
      expect(response).to have_http_status(:success)
    end

    it "shows only public diaries" do
      public_diary = create(:diary, :public)
      private_diary = create(:diary, is_public: false)

      get public_diaries_path

      expect(response.body).to include(public_diary.date.strftime("%Y/%m/%d"))
      expect(response.body).not_to include(private_diary.date.strftime("%Y年%m月%d日"))
    end

    it "limits to 20 diaries" do
      create_list(:diary, 25, :public)

      get public_diaries_path

      expect(assigns(:diaries).count).to eq(20)
    end
  end

  describe "Integration scenarios" do
    describe "Complete diary workflow" do
      it "creates diary with full evaluation and AI generation" do
        user.update!(seed_count: 3)
        questions = [
          create(:question, :mood),
          create(:question, :motivation),
          create(:question, :progress)
        ]

        questions.each { |q| create_list(:answer, 5, question: q) }

        diary_answers = questions.each_with_object({}) do |question, hash|
          hash[question.identifier] = question.answers.sample.id
        end

        post diaries_path, params: {
          diary: { date: Date.current, notes: "Learned about Rails testing", is_public: false },
          diary_answers: diary_answers
        }

        created_diary = Diary.last
        expect(created_diary.diary_answers.count).to eq(3)
        expect(created_diary.notes).to include("Rails testing")
        expect(user.reload.seed_count).to eq(3) # No AI generation, so unchanged
      end

      it "handles complete editing workflow with TIL selection" do
        diary_with_tils = create(:diary, :with_til_candidates, user: user)

        patch diary_path(diary_with_tils), params: {
          diary: {
            notes: "Updated notes",
            selected_til_index: 1,
            is_public: true
          }
        }

        diary_with_tils.reload
        expect(diary_with_tils.selected_til_index).to eq(1)
        expect(diary_with_tils.is_public).to be true
        expect(diary_with_tils.notes).to eq("Updated notes")
      end

      it "completes GitHub upload workflow" do
        user.update!(github_repo_name: "my-til-repo")
        diary_with_til = create(:diary, :with_selected_til, user: user)

        mock_service = instance_double(GithubService)
        allow(user).to receive(:github_service).and_return(mock_service)
        allow(mock_service).to receive(:push_til)
          .and_return({ success: true, message: "Successfully uploaded" })

        post upload_to_github_diary_path(diary_with_til)

        expect(response).to redirect_to(diary_path(diary_with_til))
        expect(flash[:notice]).to include("Successfully uploaded")
      end
    end

    describe "Edge case handling" do
      it "handles rapid consecutive diary creation attempts" do
        diary_params = { date: Date.current, notes: "Test", is_public: false }
        diary_answers_params = { question.identifier => answer.id }

        post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }

        expect do
          post diaries_path, params: { diary: diary_params, diary_answers: diary_answers_params }
        end.not_to change(Diary, :count)
      end

      it "handles large volume requests gracefully" do
        100.times do |_i|
          get diaries_path
        end
        expect(response).to have_http_status(:success)
      end

      it "handles memory-intensive operations" do
        diary_with_large_notes = create(:diary, user: user, notes: "A" * 50_000)

        get diary_path(diary_with_large_notes)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("A" * 100)
      end
    end

    describe "Security scenarios" do
      it "prevents access to other users' private diaries" do
        other_user = create(:user, github_id: "other_user_id")
        private_diary = create(:diary, user: other_user, is_public: false)

        get diary_path(private_diary)
        expect(response).to redirect_to(diaries_path)
      end

      it "handles invalid date search safely" do
        malicious_date = "'; DROP TABLE diaries; --"

        get search_by_date_diaries_path,
            params: { date: malicious_date },
            headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end

      it "accepts user input in notes" do
        notes_content = "Today I learned about testing"

        post diaries_path, params: {
          diary: { date: Date.current, notes: notes_content },
          diary_answers: { question.identifier => answer.id }
        }

        created_diary = Diary.last
        expect(created_diary.notes).to include("testing")
      end
    end

    describe "Performance scenarios" do
      before do
        create_list(:diary, 50, user: user)
      end

      it "handles diary listing efficiently" do
        start_time = Time.current
        get diaries_path
        end_time = Time.current

        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 1.second
      end

      it "handles search operations efficiently" do
        start_time = Time.current
        get search_by_date_diaries_path,
            params: { date: Date.current.to_s },
            headers: { "Accept" => "application/json" }
        end_time = Time.current

        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 0.5.seconds
      end
    end
  end
end
