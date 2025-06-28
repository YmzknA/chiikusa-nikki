# frozen_string_literal: true

class ChartBuilderService
  def initialize(user)
    @user = user
    @calculator = StatisticsCalculatorService.new(user)
  end

  def build_daily_trends_chart(view_type = "recent", target_month = nil)
    start_date, end_date, title_text = calculate_chart_date_range(view_type, target_month)
    diaries = fetch_diaries_for_period(start_date, end_date)
    chart_data = build_chart_data_from_diaries(diaries)
    chart_data = default_chart_data if chart_data.empty?

    {
      type: "line",
      data: build_daily_trends_data(chart_data),
      options: build_daily_trends_options(chart_data, title_text)
    }
  end

  def build_monthly_posts_chart
    monthly_data = fetch_monthly_posts_data
    {
      type: "bar",
      data: build_monthly_posts_data(monthly_data),
      options: build_monthly_posts_options
    }
  end

  def build_distribution_chart(months_back)
    period_diaries = @calculator.fetch_period_diaries(months_back)
    distributions = @calculator.calculate_all_distributions(period_diaries)
    period_text = months_back == 1 ? "直近1ヶ月" : "過去#{months_back}ヶ月間"

    {
      type: "bar",
      data: build_distribution_data(distributions),
      options: build_distribution_options(period_text)
    }
  end

  def build_learning_intensity_heatmap
    start_date, end_date, first_sunday, weeks_count = @calculator.calculate_heatmap_date_range
    diaries_data = @calculator.fetch_heatmap_diaries_data(start_date, end_date)
    weekday_data = @calculator.build_heatmap_weekday_data(diaries_data, first_sunday, weeks_count, start_date, end_date)

    {
      type: "custom_heatmap",
      data: build_heatmap_data(weekday_data, weeks_count, first_sunday, end_date),
      options: build_heatmap_options
    }
  end

  def build_habit_calendar_chart
    start_date, end_date = @calculator.calculate_calendar_date_range
    month_diaries = @calculator.fetch_month_diaries(start_date, end_date)
    calendar_weeks = @calculator.build_calendar_weeks(start_date, month_diaries)

    {
      type: "custom_calendar",
      data: build_calendar_data(calendar_weeks),
      options: build_calendar_options
    }
  end

  def build_weekday_pattern_chart(months_back)
    start_date = months_back.months.ago.to_date
    diaries = @calculator.fetch_diaries_in_range(start_date, Date.current)
    weekday_data = @calculator.build_weekday_data(diaries)
    chart_data_with_counts = @calculator.build_weekday_chart_data(weekday_data)
    period_text = months_back == 1 ? "直近1ヶ月" : "過去#{months_back}ヶ月間"

    {
      type: "bar",
      data: build_weekday_pattern_data(chart_data_with_counts),
      options: build_weekday_pattern_options(period_text)
    }
  end

  private

  def calculate_chart_date_range(view_type, target_month)
    case view_type
    when "monthly"
      date = Date.parse("#{target_month}-01")
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      title_text = "#{date.strftime('%Y年%m月')}の推移"
    else
      start_date = 30.days.ago.to_date
      end_date = Date.current
      title_text = "直近30日間の推移"
    end
    [start_date, end_date, title_text]
  end

  def fetch_diaries_for_period(start_date, end_date)
    @user.diaries.where(date: start_date..end_date)
         .includes(diary_answers: [:question, :answer])
         .order(date: :asc)
  end

  def build_chart_data_from_diaries(diaries)
    diaries.map do |diary|
      {
        date: diary.date,
        diary_id: diary.id,
        mood: @calculator.extract_answer_level(diary, :mood),
        motivation: @calculator.extract_answer_level(diary, :motivation),
        progress: @calculator.extract_answer_level(diary, :progress)
      }
    end
  end

  def default_chart_data
    [{
      date: Date.current,
      diary_id: nil,
      mood: nil,
      motivation: nil,
      progress: nil
    }]
  end

  def build_daily_trends_data(chart_data)
    {
      labels: chart_data.map { |d| d[:date].strftime("%m/%d") },
      diary_ids: chart_data.map { |d| d[:diary_id] },
      datasets: build_daily_trends_datasets(chart_data)
    }
  end

  def build_daily_trends_datasets(chart_data)
    [
      build_mood_dataset(chart_data),
      build_motivation_dataset(chart_data),
      build_progress_dataset(chart_data)
    ]
  end

  def build_mood_dataset(chart_data)
    {
      label: "気分 😊",
      data: chart_data.map { |d| d[:mood] },
      **line_dataset_style("rgba(255, 99, 132, 0.1)", "rgba(255, 99, 132, 1)")
    }
  end

  def build_motivation_dataset(chart_data)
    {
      label: "モチベーション 🔥",
      data: chart_data.map { |d| d[:motivation] },
      **line_dataset_style("rgba(255, 165, 0, 0.1)", "rgba(255, 165, 0, 1)")
    }
  end

  def build_progress_dataset(chart_data)
    {
      label: "進捗 🌱",
      data: chart_data.map { |d| d[:progress] },
      **line_dataset_style("rgba(34, 197, 94, 0.1)", "rgba(34, 197, 94, 1)")
    }
  end

  def line_dataset_style(background_color, border_color)
    {
      backgroundColor: background_color,
      borderColor: border_color,
      borderWidth: 3,
      fill: false,
      tension: 0.3,
      pointBackgroundColor: border_color,
      pointBorderColor: "#fff",
      pointBorderWidth: 3,
      pointRadius: 6,
      pointHoverRadius: 10
    }
  end

  def build_daily_trends_options(chart_data, title_text)
    {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { intersect: false, mode: "index" },
      plugins: build_daily_trends_plugins(chart_data, title_text),
      scales: build_daily_trends_scales,
      elements: { point: { hoverRadius: 10 }, line: { spanGaps: true } }
    }
  end

  def build_daily_trends_plugins(chart_data, title_text)
    {
      title: {
        display: true,
        text: chart_data.length > 1 ? title_text : "記録を続けて推移を確認しよう！",
        font: { size: 16, weight: "bold" }
      },
      legend: { position: "top" },
      tooltip: {
        backgroundColor: "rgba(255, 255, 255, 0.95)",
        titleColor: "#333",
        bodyColor: "#666",
        borderColor: "#ddd",
        borderWidth: 1,
        cornerRadius: 8,
        displayColors: true
      }
    }
  end

  def build_daily_trends_scales
    {
      y: {
        beginAtZero: true,
        max: 6,
        grid: { color: "rgba(0, 0, 0, 0.1)", drawBorder: false },
        ticks: {
          stepSize: 1,
          callback: "function(value) { return value <= 5 ? 'Lv.' + value : ''; }"
        },
        title: { display: true, text: "レベル" }
      },
      x: {
        grid: { color: "rgba(0, 0, 0, 0.05)", drawBorder: false },
        title: { display: true, text: "記録日" }
      }
    }
  end

  def fetch_monthly_posts_data
    @user.diaries
         .group_by { |diary| diary.date.beginning_of_month }
         .transform_values(&:count)
         .sort_by { |month, _count| month }
         .last(12)
  end

  def build_monthly_posts_data(monthly_data)
    {
      labels: monthly_data.map { |month, _count| month.strftime("%Y年%m月") },
      datasets: [build_monthly_posts_dataset(monthly_data)]
    }
  end

  def build_monthly_posts_dataset(monthly_data)
    {
      label: "投稿数",
      data: monthly_data.map { |_month, count| count },
      backgroundColor: "rgba(153, 102, 255, 0.6)",
      borderColor: "rgba(153, 102, 255, 1)",
      borderWidth: 1,
      borderRadius: 4,
      borderSkipped: false
    }
  end

  def build_monthly_posts_options
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        title: { display: true, text: "月別投稿数", font: { size: 16, weight: "bold" } },
        legend: { display: false }
      },
      scales: {
        y: { beginAtZero: true, grid: { color: "rgba(0, 0, 0, 0.1)" }, ticks: { stepSize: 1 } },
        x: { grid: { display: false } }
      }
    }
  end

  def build_distribution_data(distributions)
    {
      labels: %w[レベル1 レベル2 レベル3 レベル4 レベル5],
      datasets: build_distribution_datasets(distributions)
    }
  end

  def build_distribution_datasets(distributions)
    [
      build_distribution_dataset("気分 😊", distributions[:mood], "rgba(255, 99, 132, 0.6)", "rgba(255, 99, 132, 1)"),
      build_distribution_dataset("モチベーション 🔥", distributions[:motivation], "rgba(255, 165, 0, 0.6)",
                                 "rgba(255, 165, 0, 1)"),
      build_distribution_dataset("進捗 🌱", distributions[:progress], "rgba(34, 197, 94, 0.6)", "rgba(34, 197, 94, 1)")
    ]
  end

  def build_distribution_dataset(label, data, background_color, border_color)
    { label: label, data: data, backgroundColor: background_color, borderColor: border_color, borderWidth: 1 }
  end

  def build_distribution_options(period_text)
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: build_distribution_plugins(period_text),
      scales: { y: { beginAtZero: true, grid: { color: "rgba(0, 0, 0, 0.1)" }, ticks: { stepSize: 1 } },
                x: { grid: { display: false } } }
    }
  end

  def build_distribution_plugins(period_text)
    {
      title: { display: true, text: "各項目のレベル分布（#{period_text}）", font: { size: 16, weight: "bold" } },
      legend: { position: "top" },
      tooltip: { backgroundColor: "rgba(255, 255, 255, 0.95)", titleColor: "#333", bodyColor: "#666",
                 borderColor: "#ddd", borderWidth: 1, cornerRadius: 8 }
    }
  end

  def build_heatmap_data(weekday_data, weeks_count, first_sunday, end_date)
    {
      weekday_data: weekday_data, weeks_count: weeks_count,
      weekday_labels: %w[日 月 火 水 木 金 土], start_date: first_sunday, end_date: end_date
    }
  end

  def build_heatmap_options
    {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        title: { display: true, text: "学習強度ヒートマップ（直近半年）", font: { size: 16, weight: "bold" } },
        legend: { display: false }
      }
    }
  end

  def build_calendar_data(calendar_weeks)
    {
      weeks: calendar_weeks,
      month: Date.current.strftime("%Y年%m月"),
      weekdays: %w[日 月 火 水 木 金 土]
    }
  end

  def build_calendar_options
    {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        title: { display: true, text: "#{Date.current.strftime('%Y年%m月')} 習慣継続カレンダー",
                 font: { size: 16, weight: "bold" } },
        legend: { display: false }
      }
    }
  end

  def build_weekday_pattern_data(chart_data_with_counts)
    weekday_names = %w[月 火 水 木 金 土 日]
    {
      labels: weekday_names,
      datasets: build_weekday_pattern_datasets(chart_data_with_counts)
    }
  end

  def build_weekday_pattern_datasets(chart_data_with_counts)
    [
      build_weekday_mood_dataset(chart_data_with_counts),
      build_weekday_motivation_dataset(chart_data_with_counts),
      build_weekday_progress_dataset(chart_data_with_counts)
    ]
  end

  def build_weekday_mood_dataset(chart_data_with_counts)
    {
      label: "気分 😊",
      data: chart_data_with_counts.map { |d| d[:mood] },
      **bar_dataset_style("rgba(255, 99, 132, 0.8)", "rgba(255, 99, 132, 1)"),
      counts: chart_data_with_counts.map { |d| d[:count] }
    }
  end

  def build_weekday_motivation_dataset(chart_data_with_counts)
    {
      label: "モチベーション 🔥",
      data: chart_data_with_counts.map { |d| d[:motivation] },
      **bar_dataset_style("rgba(255, 165, 0, 0.8)", "rgba(255, 165, 0, 1)"),
      counts: chart_data_with_counts.map { |d| d[:count] }
    }
  end

  def build_weekday_progress_dataset(chart_data_with_counts)
    {
      label: "進捗 🌱",
      data: chart_data_with_counts.map { |d| d[:progress] },
      **bar_dataset_style("rgba(34, 197, 94, 0.8)", "rgba(34, 197, 94, 1)"),
      counts: chart_data_with_counts.map { |d| d[:count] }
    }
  end

  def bar_dataset_style(background_color, border_color)
    {
      backgroundColor: background_color,
      borderColor: border_color,
      borderWidth: 1,
      borderRadius: 4,
      borderSkipped: false
    }
  end

  def build_weekday_pattern_options(period_text)
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: build_weekday_pattern_plugins(period_text),
      scales: build_weekday_pattern_scales,
      interaction: { intersect: false, mode: "index" }
    }
  end

  def build_weekday_pattern_plugins(period_text)
    {
      title: {
        display: true,
        text: "曜日別パフォーマンスパターン（#{period_text}）",
        font: { size: 16, weight: "bold" }
      },
      legend: { position: "top" },
      tooltip: {
        backgroundColor: "rgba(255, 255, 255, 0.95)",
        titleColor: "#333",
        bodyColor: "#666",
        borderColor: "#ddd",
        borderWidth: 1,
        cornerRadius: 8
      }
    }
  end

  def build_weekday_pattern_scales
    {
      y: {
        beginAtZero: true,
        max: 6,
        grid: { color: "rgba(0, 0, 0, 0.1)", drawBorder: false },
        ticks: {
          stepSize: 1,
          callback: "function(value) { return value <= 5 ? 'Lv.' + value : ''; }"
        },
        title: { display: true, text: "パフォーマンスレベル" }
      },
      x: {
        grid: { display: false },
        title: { display: true, text: "曜日" }
      }
    }
  end
end
