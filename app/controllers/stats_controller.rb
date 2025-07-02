# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :authenticate_user!
  before_action :setup_chart_builder

  EMPTY_CHARTS_DATA = {
    daily_trends_chart: { labels: [], datasets: [] },
    monthly_posts_chart: { labels: [], datasets: [] },
    learning_intensity_heatmap: { labels: [], datasets: [] },
    habit_calendar_chart: { labels: [], datasets: [] },
    weekday_pattern_chart: { labels: [], datasets: [] },
    distribution_chart: { labels: [], datasets: [] }
  }.freeze

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
    cache_key = generate_cache_key
    cached_charts = fetch_charts_with_fallback(cache_key)
    assign_chart_data(cached_charts)
  end

  # キャッシュキー生成（セキュリティ強化済み）
  def generate_cache_key
    # user_idをハッシュ化して個人情報を難読化
    user_hash = Digest::SHA256.hexdigest(current_user.id.to_s)[0, 8]
    "stats_charts_#{user_hash}_#{@view_type}_#{@target_month}_" \
      "#{@weekday_months}_#{@distribution_months}"
  end

  def fetch_charts_with_fallback(cache_key)
    Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
      Rails.logger.debug "Building charts data for cache key: #{cache_key}" unless Rails.env.production?
      build_charts_data
    end
  rescue Redis::ConnectionError => e
    handle_cache_error(e, cache_key)
    build_charts_data
  end

  def assign_chart_data(cached_charts)
    @daily_trends_chart = cached_charts[:daily_trends_chart]
    @monthly_posts_chart = cached_charts[:monthly_posts_chart]
    @learning_intensity_heatmap = cached_charts[:learning_intensity_heatmap]
    @habit_calendar_chart = cached_charts[:habit_calendar_chart]
    @weekday_pattern_chart = cached_charts[:weekday_pattern_chart]
    @distribution_chart = cached_charts[:distribution_chart]
  end

  def handle_cache_error(error, cache_key)
    Rails.logger.error "Cache service error: #{error.class.name}"
    Rails.logger.debug "Cache error details for key #{cache_key}: #{error.message}" unless Rails.env.production?
  end

  def build_charts_data
    {
      daily_trends_chart: @chart_builder.build_daily_trends_chart(@view_type, @target_month),
      monthly_posts_chart: @chart_builder.build_monthly_posts_chart,
      learning_intensity_heatmap: @chart_builder.build_learning_intensity_heatmap,
      habit_calendar_chart: @chart_builder.build_habit_calendar_chart,
      weekday_pattern_chart: @chart_builder.build_weekday_pattern_chart(@weekday_months),
      distribution_chart: @chart_builder.build_distribution_chart(@distribution_months)
    }
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error("Database error building chart data: #{e.class.name}")
    Rails.logger.debug("Database error details: #{e.message}") unless Rails.env.production?
    empty_charts_data
  rescue NoMethodError, ArgumentError => e
    Rails.logger.error("Chart builder error: #{e.class.name}")
    Rails.logger.debug("Chart builder error details: #{e.message}") unless Rails.env.production?
    empty_charts_data
  end

  def empty_charts_data
    EMPTY_CHARTS_DATA
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
