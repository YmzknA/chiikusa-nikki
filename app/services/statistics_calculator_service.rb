# frozen_string_literal: true

class StatisticsCalculatorService
  HEATMAP_DAYS = 120
  CALENDAR_WEEKS = 6
  CALENDAR_DAYS = (CALENDAR_WEEKS * 7) - 1

  def initialize(user)
    @user = user
  end

  def extract_answer_level(diary, identifier)
    diary.diary_answers
         .joins(:question)
         .find_by(questions: { identifier: identifier })
         &.answer
         &.level
  end

  def calculate_level_distribution(diaries, identifier)
    levels = diaries.map { |diary| extract_answer_level(diary, identifier) }.compact
    (1..MAX_LEVEL).map { |level| levels.count(level) }
  end

  def calculate_average_level(diaries, identifier)
    levels = diaries.map { |diary| extract_answer_level(diary, identifier) }.compact
    levels.any? ? (levels.sum.to_f / levels.length).round(1) : 0
  end

  def calculate_learning_intensity(diary)
    return 0 unless diary

    mood = extract_answer_level(diary, :mood) || 0
    motivation = extract_answer_level(diary, :motivation) || 0
    progress = extract_answer_level(diary, :progress) || 0

    total_intensity = mood + motivation + progress
    max_total_score = MAX_LEVEL * ANSWER_CATEGORIES
    intensity_scale = INTENSITY_SCALE_MAX
    (total_intensity / max_total_score.to_f * intensity_scale).round(1)
  end

  def fetch_period_diaries(months_back)
    start_date = months_back.months.ago.to_date
    @user.diaries.where(date: start_date..Date.current)
         .includes(diary_answers: [:question, :answer])
  end

  def fetch_diaries_in_range(start_date, end_date)
    @user.diaries.where(date: start_date..end_date)
         .includes(diary_answers: [:question, :answer])
  end

  def calculate_all_distributions(period_diaries)
    {
      mood: calculate_level_distribution(period_diaries, :mood),
      motivation: calculate_level_distribution(period_diaries, :motivation),
      progress: calculate_level_distribution(period_diaries, :progress)
    }
  end

  def calculate_heatmap_date_range
    start_date = HEATMAP_DAYS.days.ago.to_date
    end_date = Date.current
    first_sunday = start_date - start_date.wday.days
    total_days = (end_date - first_sunday).to_i + 1
    weeks_count = (total_days / 7.0).ceil
    [start_date, end_date, first_sunday, weeks_count]
  end

  def fetch_heatmap_diaries_data(start_date, end_date)
    @user.diaries.where(date: start_date..end_date)
         .includes(diary_answers: [:question, :answer])
         .group_by(&:date)
  end

  def build_heatmap_weekday_data(diaries_data, first_sunday, weeks_count, start_date, end_date)
    weekday_data = initialize_weekday_data
    date_range = { first_sunday: first_sunday, weeks_count: weeks_count, start_date: start_date, end_date: end_date }
    populate_weekday_data(weekday_data, diaries_data, date_range)
    weekday_data
  end

  def calculate_calendar_date_range
    start_date = Date.current.beginning_of_month
    end_date = Date.current.end_of_month
    [start_date, end_date]
  end

  def fetch_month_diaries(start_date, end_date)
    @user.diaries.where(date: start_date..end_date)
         .includes(diary_answers: [:question, :answer])
         .index_by(&:date)
  end

  def build_calendar_weeks(start_date, month_diaries)
    calendar_weeks = []
    current_week = []
    first_sunday = start_date - start_date.wday.days

    (0..CALENDAR_DAYS).each do |days_offset|
      date = first_sunday + days_offset.days
      day_data = build_calendar_day_data(date, month_diaries)
      current_week << day_data

      if date.saturday?
        calendar_weeks << current_week
        current_week = []
      end
    end

    calendar_weeks << current_week unless current_week.empty?
    calendar_weeks
  end

  def build_weekday_data(diaries)
    weekday_data = {}
    (0..6).each do |wday|
      weekday_diaries = diaries.select { |diary| diary.date.wday == wday }
      weekday_data[wday] = calculate_weekday_averages(weekday_diaries)
    end
    weekday_data
  end

  def build_weekday_chart_data(weekday_data)
    weekday_order = [1, 2, 3, 4, 5, 6, 0]
    weekday_names = %w[月 火 水 木 金 土 日]

    weekday_order.map.with_index do |wday, index|
      {
        mood: weekday_data[wday][:mood],
        motivation: weekday_data[wday][:motivation],
        progress: weekday_data[wday][:progress],
        count: weekday_data[wday][:count],
        day_name: weekday_names[index]
      }
    end
  end

  # 公開定数
  MAX_LEVEL = 5
  ANSWER_CATEGORIES = 3
  INTENSITY_SCALE_MAX = 4

  private

  def initialize_weekday_data
    weekday_data = {}
    (0..6).each { |wday| weekday_data[wday] = [] }
    weekday_data
  end

  def populate_weekday_data(weekday_data, diaries_data, date_range)
    (0...date_range[:weeks_count]).each do |week_index|
      (0..6).each do |wday|
        date = date_range[:first_sunday] + ((week_index * 7) + wday).days
        day_data = build_day_data(date, diaries_data, week_index, date_range[:start_date], date_range[:end_date])
        weekday_data[wday] << day_data
      end
    end
  end

  def build_day_data(date, diaries_data, week_index, start_date, end_date)
    if date <= end_date
      diary = diaries_data[date]&.first
      intensity = calculate_learning_intensity(diary)
      {
        date: date, intensity: intensity, week_index: week_index,
        is_future: date > Date.current, is_in_range: date.between?(start_date, end_date)
      }
    else
      { date: date, intensity: 0, week_index: week_index, is_future: true, is_in_range: false }
    end
  end

  def build_calendar_day_data(date, month_diaries)
    diary = month_diaries[date]
    has_record = diary.present?
    intensity = has_record ? calculate_learning_intensity(diary) : 0

    {
      date: date, day: date.day, has_record: has_record,
      is_current_month: date.month == Date.current.month,
      is_today: date == Date.current, intensity: intensity,
      weekday: date.strftime("%a")
    }
  end

  def calculate_weekday_averages(weekday_diaries)
    return { mood: 0, motivation: 0, progress: 0, count: 0 } unless weekday_diaries.any?

    {
      mood: calculate_average_level(weekday_diaries, :mood),
      motivation: calculate_average_level(weekday_diaries, :motivation),
      progress: calculate_average_level(weekday_diaries, :progress),
      count: weekday_diaries.length
    }
  end
end
