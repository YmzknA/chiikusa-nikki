require "rails_helper"

RSpec.describe "Stats", type: :request do
  let(:user) { create(:user, :with_github) }

  before do
    sign_in user
  end

  describe "GET /stats" do
    it "returns http success" do
      get stats_path
      expect(response).to have_http_status(:success)
    end

    it "sets up chart builder service" do
      get stats_path
      expect(assigns(:chart_builder)).to be_a(ChartBuilderService)
    end

    it "builds all required charts" do
      get stats_path

      expect(assigns(:daily_trends_chart)).to be_present
      expect(assigns(:monthly_posts_chart)).to be_present
      expect(assigns(:learning_intensity_heatmap)).to be_present
      expect(assigns(:habit_calendar_chart)).to be_present
      expect(assigns(:weekday_pattern_chart)).to be_present
      expect(assigns(:distribution_chart)).to be_present
    end

    it "uses default parameters when none provided" do
      get stats_path

      expect(assigns(:view_type)).to eq("recent")
      expect(assigns(:target_month)).to eq(Date.current.strftime("%Y-%m"))
      expect(assigns(:weekday_months)).to eq(1)
      expect(assigns(:distribution_months)).to eq(1)
    end

    it "accepts custom parameters" do
      get stats_path, params: {
        view_type: "monthly",
        target_month: "2024-01",
        weekday_months: 3,
        distribution_months: 6
      }

      expect(assigns(:view_type)).to eq("monthly")
      expect(assigns(:target_month)).to eq("2024-01")
      expect(assigns(:weekday_months)).to eq(3)
      expect(assigns(:distribution_months)).to eq(6)
    end

    it "clamps month parameters to valid ranges" do
      get stats_path, params: {
        weekday_months: 15,
        distribution_months: 0
      }

      expect(assigns(:weekday_months)).to eq(12)
      expect(assigns(:distribution_months)).to eq(1)
    end

    it "requires authentication" do
      sign_out user
      get stats_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "Turbo Frame requests" do
    it "renders daily trends partial for turbo frame request" do
      get stats_path,
          headers: { "Turbo-Frame" => "daily-trends-chart" }

      expect(response).to render_template("stats/charts/_daily_trends")
    end

    it "renders weekday pattern partial for turbo frame request" do
      get stats_path,
          headers: { "Turbo-Frame" => "weekday-pattern-chart" }

      expect(response).to render_template("stats/charts/_weekday_pattern")
    end

    it "renders distribution partial for turbo frame request" do
      get stats_path,
          headers: { "Turbo-Frame" => "distribution-chart" }

      expect(response).to render_template("stats/charts/_distribution")
    end

    it "renders default partial for unknown turbo frame" do
      get stats_path,
          headers: { "Turbo-Frame" => "unknown-chart" }

      expect(response).to render_template("stats/_index")
    end
  end

  describe "with user data" do
    before do
      # Create some test data
      create_list(:diary, 5, :with_answers, user: user)
    end

    it "processes user's diary data for charts" do
      get stats_path

      expect(response).to have_http_status(:success)
      expect(assigns(:daily_trends_chart)).to be_present
    end

    it "handles empty data gracefully" do
      user.diaries.destroy_all

      get stats_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "chart parameters validation" do
    it "handles invalid view_type" do
      get stats_path, params: { view_type: "invalid" }
      expect(assigns(:view_type)).to eq("invalid")
    end

    it "handles invalid target_month format" do
      get stats_path, params: { target_month: "invalid" }
      expect(assigns(:target_month)).to eq("invalid")
    end

    it "handles non-numeric month parameters" do
      get stats_path, params: {
        weekday_months: "invalid",
        distribution_months: "invalid"
      }

      expect(assigns(:weekday_months)).to eq(1)
      expect(assigns(:distribution_months)).to eq(1)
    end
  end
end
