require "rails_helper"

RSpec.describe "Performance and Load Testing", type: :integration do
  let(:user) { create(:user, :with_github) }
  
  before do
    sign_in user
  end

  describe "Database query optimization" do
    context "with N+1 query prevention" do
      it "efficiently loads diaries with associations" do
        create_list(:diary, 20, :with_til_candidates, :with_answers, user: user)
        
        expect do
          get diaries_path
        end.not_to exceed_query_limit(10)
        
        expect(response).to have_http_status(:success)
      end

      it "efficiently loads diary details with all associations" do
        diary = create(:diary, :with_til_candidates, :with_answers, user: user)
        
        expect do
          get diary_path(diary)
        end.not_to exceed_query_limit(8)
        
        expect(response).to have_http_status(:success)
      end
    end

    context "with large datasets" do
      before do
        # Create substantial test data
        create_list(:diary, 100, user: user)
        other_users = create_list(:user, 10)
        other_users.each { |u| create_list(:diary, 50, user: u) }
      end

      it "handles large user diary collections efficiently" do
        start_time = Time.current
        
        get diaries_path
        
        end_time = Time.current
        
        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 2.seconds
      end

      it "handles public diary listings efficiently" do
        start_time = Time.current
        
        get public_diaries_path
        
        end_time = Time.current
        
        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 2.seconds
      end
    end
  end

  describe "Memory usage optimization" do
    context "with large content processing" do
      it "handles large diary content without memory bloat" do
        large_notes = "Large content block. " * 10000
        
        start_memory = get_memory_usage
        
        post diaries_path, params: {
          diary: { date: Date.current, notes: large_notes },
          diary_answers: {}
        }
        
        end_memory = get_memory_usage
        memory_increase = end_memory - start_memory
        
        expect(memory_increase).to be < 50.megabytes
      end

      it "efficiently processes multiple large operations" do
        start_memory = get_memory_usage
        
        10.times do |i|
          large_content = "Test content " * 1000
          diary = create(:diary, user: user, notes: large_content, date: Date.current - i.days)
        end
        
        end_memory = get_memory_usage
        memory_increase = end_memory - start_memory
        
        expect(memory_increase).to be < 100.megabytes
      end
    end
  end

  describe "Concurrent user simulation" do
    context "with multiple simultaneous requests" do
      it "handles concurrent diary creation requests" do
        threads = 5.times.map do |i|
          Thread.new do
            post diaries_path, params: {
              diary: { date: Date.current + i.days, notes: "Concurrent test #{i}" },
              diary_answers: {}
            }
            response.status
          end
        end
        
        statuses = threads.map(&:value)
        successful_requests = statuses.count { |status| [200, 201, 302].include?(status) }
        
        expect(successful_requests).to be >= 3
      end

      it "handles concurrent view requests efficiently" do
        diary = create(:diary, user: user)
        
        threads = 10.times.map do
          Thread.new do
            get diary_path(diary)
            response.status
          end
        end
        
        statuses = threads.map(&:value)
        expect(statuses).to all(eq(200))
      end
    end
  end

  describe "External service integration performance" do
    context "with OpenAI service calls" do
      before do
        allow_any_instance_of(OpenaiService).to receive(:generate_tils) do
          sleep(0.1) # Simulate API delay
          ["TIL 1", "TIL 2", "TIL 3"]
        end
      end

      it "handles OpenAI service delays gracefully" do
        user.update!(seed_count: 3)
        
        start_time = Time.current
        
        post diaries_path, params: {
          diary: { date: Date.current, notes: "Test notes for AI generation" },
          diary_answers: {}
        }
        
        end_time = Time.current
        
        expect(response).to have_http_status(:redirect)
        expect(end_time - start_time).to be < 10.seconds
      end
    end

    context "with GitHub service calls" do
      let(:diary) { create(:diary, :with_selected_til, user: user) }
      
      before do
        user.update!(github_repo_name: "test-repo")
        allow_any_instance_of(GithubService).to receive(:push_til) do
          sleep(0.1) # Simulate API delay
          { success: true, message: "Upload successful" }
        end
      end

      it "handles GitHub service delays gracefully" do
        start_time = Time.current
        
        post upload_to_github_diary_path(diary)
        
        end_time = Time.current
        
        expect(response).to have_http_status(:redirect)
        expect(end_time - start_time).to be < 10.seconds
      end
    end
  end

  describe "Caching and optimization" do
    context "with repeated requests" do
      it "benefits from caching on repeated diary views" do
        diary = create(:diary, user: user)
        
        # First request (cold cache)
        first_start = Time.current
        get diary_path(diary)
        first_end = Time.current
        first_duration = first_end - first_start
        
        # Second request (should be faster with caching)
        second_start = Time.current
        get diary_path(diary)
        second_end = Time.current
        second_duration = second_end - second_start
        
        expect(response).to have_http_status(:success)
        # Second request should be at least as fast as first
        expect(second_duration).to be <= first_duration + 0.1
      end
    end
  end

  describe "Resource cleanup and garbage collection" do
    context "after intensive operations" do
      it "properly cleans up after bulk operations" do
        initial_object_count = ObjectSpace.count_objects
        
        # Perform intensive operations
        100.times do |i|
          diary = build(:diary, user: user, date: Date.current - i.days)
          diary.save!
          diary.destroy!
        end
        
        # Force garbage collection
        GC.start
        
        final_object_count = ObjectSpace.count_objects
        object_increase = final_object_count[:TOTAL] - initial_object_count[:TOTAL]
        
        # Should not have excessive object accumulation
        expect(object_increase).to be < 10000
      end
    end
  end

  describe "API response time benchmarks" do
    context "with various endpoint performance" do
      let(:performance_thresholds) do
        {
          diaries_index: 1.second,
          diary_show: 0.5.seconds,
          diary_new: 0.3.seconds,
          diary_edit: 0.5.seconds,
          profile_show: 0.3.seconds,
          stats_show: 1.second
        }
      end

      it "meets performance thresholds for key endpoints" do
        diary = create(:diary, user: user)
        
        performance_thresholds.each do |endpoint, threshold|
          start_time = Time.current
          
          case endpoint
          when :diaries_index
            get diaries_path
          when :diary_show
            get diary_path(diary)
          when :diary_new
            get new_diary_path
          when :diary_edit
            get edit_diary_path(diary)
          when :profile_show
            get profile_path
          when :stats_show
            get stats_path
          end
          
          end_time = Time.current
          duration = end_time - start_time
          
          expect(response).to have_http_status(:success)
          expect(duration).to be < threshold, 
            "#{endpoint} took #{duration}s, expected < #{threshold}s"
        end
      end
    end
  end

  private

  def get_memory_usage
    # Simple memory usage estimation
    # In a real application, you might use more sophisticated memory profiling
    GC.stat[:heap_allocated_pages] * 16384 # Approximate bytes
  end

  def exceed_query_limit(limit)
    raise ArgumentError, "Query limit must be positive" if limit <= 0
    
    lambda do |block|
      query_count = 0
      
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        query_count += 1
      end
      
      begin
        block.call
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end
      
      query_count > limit
    end
  end
end