# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :setup_chart_builder

  def index
    setup_chart_parameters
    build_all_charts
    handle_turbo_frame_request
  end

  private

  def setup_chart_builder
    @chart_builder = ChartBuilderService.new(current_user)
  end

  def setup_chart_parameters
    @view_type = params[:view_type] || "recent"
    @target_month = params[:target_month] || Date.current.strftime("%Y-%m")
    @weekday_months = (params[:weekday_months]&.to_i || 1).clamp(1, 12)
    @distribution_months = (params[:distribution_months]&.to_i || 1).clamp(1, 12)
  end

  def build_all_charts
    @daily_trends_chart = @chart_builder.build_daily_trends_chart(@view_type, @target_month)
    @monthly_posts_chart = @chart_builder.build_monthly_posts_chart
    @learning_intensity_heatmap = @chart_builder.build_learning_intensity_heatmap
    @habit_calendar_chart = @chart_builder.build_habit_calendar_chart
    @weekday_pattern_chart = @chart_builder.build_weekday_pattern_chart(@weekday_months)
    @distribution_chart = @chart_builder.build_distribution_chart(@distribution_months)
  end

  def handle_turbo_frame_request
    respond_to do |format|
      format.html do
        render partial: turbo_frame_partial, locals: chart_locals if turbo_frame_request?
      end
    end
  end

  def turbo_frame_partial
    frame_id = request.headers["Turbo-Frame"]
    case frame_id
    when "daily-trends-chart"
      "stats/charts/daily_trends"
    when "weekday-pattern-chart"
      "stats/charts/weekday_pattern"
    when "distribution-chart"
      "stats/charts/distribution"
    else
      "stats/index"
    end
  end

  def chart_locals
    {
      view_type: @view_type,
      target_month: @target_month,
      daily_trends_chart: @daily_trends_chart,
      weekday_pattern_chart: @weekday_pattern_chart,
      distribution_chart: @distribution_chart
    }
  end
end
