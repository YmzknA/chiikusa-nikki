require "rails_helper"

RSpec.describe "Error Handling and Boundary Value Tests", type: :integration do
  let(:user) { create(:user, :with_github) }
  
  before do
    sign_in user
  end

  describe "Database constraint violations" do
    context "when unique constraints are violated" do
      it "handles duplicate diary creation gracefully" do
        existing_diary = create(:diary, user: user, date: Date.current)
        
        post diaries_path, params: {
          diary: { date: Date.current, notes: "Duplicate attempt" },
          diary_answers: {}
        }
        
        expect(response).to render_template(:new)
        expect(assigns(:existing_diary_for_error)).to eq(existing_diary)
      end

      it "handles duplicate user creation attempts" do
        existing_user = create(:user, github_id: "12345")
        
        auth_data = double(
          provider: "github",
          uid: "12345",
          info: double(email: "test@example.com"),
          credentials: double(token: "token")
        )
        
        result = User.from_omniauth(auth_data)
        expect(result).to eq(existing_user)
      end
    end

    context "when foreign key constraints are violated" do
      it "prevents orphaned diary answers" do
        diary = create(:diary, user: user)
        question = create(:question)
        answer = create(:answer, question: question)
        
        diary_answer = create(:diary_answer, diary: diary, question: question, answer: answer)
        question.destroy
        
        expect(DiaryAnswer.find_by(id: diary_answer.id)).to be_nil
      end
      
      it "prevents orphaned TIL candidates" do
        diary = create(:diary, user: user)
        til_candidate = create(:til_candidate, diary: diary)
        
        diary.destroy
        
        expect(TilCandidate.find_by(id: til_candidate.id)).to be_nil
      end
    end
  end

  describe "Input validation boundary testing" do
    context "with extremely large inputs" do
      it "handles very long diary notes" do
        long_notes = "A" * 100000
        
        post diaries_path, params: {
          diary: { date: Date.current, notes: long_notes },
          diary_answers: {}
        }
        
        if response.successful?
          created_diary = Diary.last
          expect(created_diary.notes.length).to eq(100000)
        else
          expect(response).to render_template(:new)
        end
      end

      it "handles extremely long usernames" do
        long_username = "a" * 1000
        user.update(username: long_username, validate: false)
        
        get profile_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with special characters and encoding" do
      let(:special_chars_test_cases) do
        [
          "日本語テスト 🚀",
          "\u0000\u0001\u0002", # Null bytes
          "emoji spam: " + "🔥" * 100,
          "SQL injection: '; DROP TABLE users; --",
          "XSS attempt: <script>alert('xss')</script>",
          "Unicode spam: " + "\u{1F4A9}" * 50,
          "Mixed encoding: café naïve résumé"
        ]
      end

      it "safely handles special characters in diary notes" do
        special_chars_test_cases.each do |test_input|
          diary = build(:diary, user: user, notes: test_input)
          
          expect { diary.save! }.not_to raise_error
          
          if diary.persisted?
            expect(diary.reload.notes).to be_a(String)
          end
        end
      end

      it "safely handles special characters in usernames" do
        special_chars_test_cases.each do |test_input|
          user_with_special_chars = build(:user, username: test_input)
          
          expect { user_with_special_chars.save(validate: false) }.not_to raise_error
        end
      end
    end

    context "with null and empty values" do
      let(:null_value_scenarios) do
        [
          { notes: nil, date: Date.current },
          { notes: "", date: Date.current },
          { notes: "   ", date: Date.current },
          { notes: "\n\t  \n", date: Date.current }
        ]
      end

      it "handles null and empty values gracefully" do
        null_value_scenarios.each do |scenario|
          diary = build(:diary, user: user, **scenario)
          
          expect { diary.save }.not_to raise_error
          
          if diary.persisted?
            expect(diary.notes).to eq(scenario[:notes])
          end
        end
      end
    end
  end

  describe "Memory and performance stress testing" do
    context "with high-volume data creation" do
      it "handles bulk diary creation efficiently" do
        diary_count = 100
        
        start_time = Time.current
        
        expect do
          diary_count.times do |i|
            create(:diary, user: user, date: Date.current - i.days)
          end
        end.to change(Diary, :count).by(diary_count)
        
        end_time = Time.current
        expect(end_time - start_time).to be < 30.seconds
      end

      it "handles complex query operations efficiently" do
        # Create substantial test data
        create_list(:diary, 50, user: user)
        other_users = create_list(:user, 10)
        other_users.each { |u| create_list(:diary, 20, user: u) }
        
        start_time = Time.current
        
        # Complex query operations
        user_diary_count = user.diaries.count
        recent_diaries = user.diaries.where("date > ?", 30.days.ago).count
        public_diaries = Diary.where(is_public: true).count
        
        end_time = Time.current
        
        expect(user_diary_count).to be >= 50
        expect(end_time - start_time).to be < 5.seconds
      end
    end

    context "with concurrent access patterns" do
      it "handles simultaneous user creation safely" do
        auth_data_base = {
          provider: "github",
          info: double(email: "concurrent@example.com"),
          credentials: double(token: "token")
        }
        
        threads = 5.times.map do |i|
          Thread.new do
            auth_data = double(
              **auth_data_base,
              uid: "concurrent_#{i}"
            )
            User.from_omniauth(auth_data)
          end
        end
        
        results = threads.map(&:value)
        expect(results.compact.size).to eq(5)
        expect(results.map(&:github_id).uniq.size).to eq(5)
      end

      it "handles concurrent diary creation attempts" do
        question = create(:question)
        answer = create(:answer, question: question)
        
        threads = 3.times.map do |i|
          Thread.new do
            begin
              create(:diary, 
                user: user, 
                date: Date.current + i.days,
                notes: "Concurrent diary #{i}"
              )
            rescue => e
              Rails.logger.warn "Concurrent creation error: #{e.message}"
              nil
            end
          end
        end
        
        results = threads.map(&:value).compact
        expect(results.size).to be >= 1
      end
    end
  end

  describe "External service failure scenarios" do
    context "when OpenAI service fails" do
      before do
        allow_any_instance_of(OpenaiService).to receive(:generate_tils).and_raise(StandardError, "OpenAI API failure")
      end

      it "handles OpenAI failure gracefully during diary creation" do
        user.update!(seed_count: 3)
        
        post diaries_path, params: {
          diary: { date: Date.current, notes: "Test notes" },
          diary_answers: {}
        }
        
        expect(response).to render_template(:new)
        expect(flash[:alert]).to include("TIL生成に失敗")
      end
    end

    context "when GitHub service fails" do
      let(:diary) { create(:diary, :with_selected_til, user: user) }
      
      before do
        user.update!(github_repo_name: "test-repo")
        allow_any_instance_of(GithubService).to receive(:push_til).and_raise(StandardError, "GitHub API failure")
      end

      it "handles GitHub failure gracefully during upload" do
        post upload_to_github_diary_path(diary)
        
        expect(response).to redirect_to(diary_path(diary))
        expect(flash[:alert]).to include("GitHubへのアップロードに失敗")
      end
    end

    context "when database connection fails" do
      it "handles database errors gracefully" do
        allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)
        
        get diaries_path
        
        expect(response).to have_http_status(:error)
      end
    end
  end

  describe "Authentication and authorization edge cases" do
    context "with invalid authentication states" do
      it "handles expired sessions gracefully" do
        sign_out user
        
        post diaries_path, params: {
          diary: { date: Date.current, notes: "Unauthorized attempt" }
        }
        
        expect(response).to redirect_to(new_user_session_path)
      end

      it "prevents access to other users' resources" do
        other_user = create(:user, github_id: "other_user")
        other_diary = create(:diary, user: other_user)
        
        get diary_path(other_diary)
        
        expect(response).to redirect_to(diaries_path)
      end
    end

    context "with malformed authentication data" do
      let(:malformed_auth_scenarios) do
        [
          { provider: nil, uid: "123", info: double(email: "test@example.com") },
          { provider: "github", uid: nil, info: double(email: "test@example.com") },
          { provider: "github", uid: "123", info: nil },
          { provider: "", uid: "", info: double(email: "") }
        ]
      end

      it "handles malformed authentication data" do
        malformed_auth_scenarios.each do |auth_data|
          auth_double = double(**auth_data, credentials: double(token: "token"))
          
          expect { User.from_omniauth(auth_double) }.not_to raise_error
        end
      end
    end
  end

  describe "File system and storage edge cases" do
    context "with file upload scenarios" do
      it "handles missing file uploads gracefully" do
        post diaries_path, params: {
          diary: { date: Date.current, notes: "Test" },
          file_upload: nil
        }
        
        expect(response).to have_http_status(:success).or(render_template(:new))
      end
    end

    context "with session storage limits" do
      it "handles large session data gracefully" do
        large_data = "x" * 10000
        
        session[:large_data] = large_data
        
        get diaries_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "Time and date edge cases" do
    context "with timezone handling" do
      around do |example|
        original_zone = Time.zone
        Time.zone = 'UTC'
        example.run
        Time.zone = original_zone
      end

      it "handles timezone changes correctly" do
        diary = create(:diary, user: user, date: Date.current)
        
        Time.zone = 'Asia/Tokyo'
        
        get diary_path(diary)
        expect(response).to have_http_status(:success)
      end
    end

    context "with date boundary values" do
      let(:boundary_dates) do
        [
          Date.new(1900, 1, 1),
          Date.new(2000, 2, 29), # Leap year
          Date.new(2100, 12, 31),
          Date.current + 100.years
        ]
      end

      it "handles extreme date values" do
        boundary_dates.each do |test_date|
          diary = build(:diary, user: user, date: test_date)
          
          expect { diary.save }.not_to raise_error
          
          if diary.persisted?
            expect(diary.date).to eq(test_date)
          end
        end
      end
    end
  end

  describe "Internationalization and localization edge cases" do
    context "with different locales" do
      around do |example|
        original_locale = I18n.locale
        example.run
        I18n.locale = original_locale
      end

      it "handles missing translation keys gracefully" do
        I18n.locale = :ja
        
        get diaries_path
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("translation missing")
      end
    end
  end
end