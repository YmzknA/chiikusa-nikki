class StatsController < ApplicationController
  def index
    # 表示期間のパラメータ処理
    @view_type = params[:view_type] || "recent" # 'recent' or 'monthly'
    @target_month = params[:target_month] || Date.current.strftime("%Y-%m")

    @daily_trends_chart = build_daily_trends_chart(@view_type, @target_month)
    @monthly_posts_chart = build_monthly_posts_chart
    @learning_intensity_heatmap = build_learning_intensity_heatmap
    @habit_calendar_chart = build_habit_calendar_chart
    @achievement_gauge_chart = build_achievement_gauge_chart
    @mood_progress_correlation_chart = build_mood_progress_correlation_chart
    @weekday_pattern_chart = build_weekday_pattern_chart
    @distribution_chart = build_distribution_chart

    # Turbo Frameリクエストの場合は部分テンプレートをレンダリング
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: turbo_frame_partial, locals: chart_locals
        end
      end
    end
  end


  private

  def turbo_frame_partial
    frame_id = request.headers['Turbo-Frame']
    case frame_id
    when 'daily-trends-chart'
      'stats/charts/daily_trends'
    when 'weekday-pattern-chart'
      'stats/charts/weekday_pattern'
    when 'distribution-chart'
      'stats/charts/distribution'
    else
      'stats/index'
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

  def build_daily_trends_chart(view_type = "recent", target_month = nil)
    # 表示期間に応じてデータ取得期間を設定
    case view_type
    when "monthly"
      # 指定月のデータを取得
      date = Date.parse("#{target_month}-01")
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      title_text = "#{date.strftime('%Y年%m月')}の推移"
    else
      # 直近30日のデータを取得
      start_date = 30.days.ago.to_date
      end_date = Date.current
      title_text = "直近30日間の推移"
    end

    # 実際に日記がある日のみのデータを取得
    diaries = current_user.diaries.where(date: start_date..end_date)
                          .includes(diary_answers: [:question, :answer])
                          .order(date: :asc)

    # 日記がある日のみでチャートデータを構築
    chart_data = diaries.map do |diary|
      {
        date: diary.date,
        mood: extract_answer_level(diary, :mood),
        motivation: extract_answer_level(diary, :motivation),
        progress: extract_answer_level(diary, :progress)
      }
    end

    # 記録がない場合の処理
    if chart_data.empty?
      chart_data = [{
        date: Date.current,
        mood: nil,
        motivation: nil,
        progress: nil
      }]
    end

    {
      type: "line",
      data: {
        labels: chart_data.map { |d| d[:date].strftime("%m/%d") },
        datasets: [
          {
            label: "気分 😊",
            data: chart_data.map { |d| d[:mood] },
            backgroundColor: "rgba(255, 99, 132, 0.1)",
            borderColor: "rgba(255, 99, 132, 1)",
            borderWidth: 3,
            fill: false,
            tension: 0.3,
            pointBackgroundColor: "rgba(255, 99, 132, 1)",
            pointBorderColor: "#fff",
            pointBorderWidth: 3,
            pointRadius: 6,
            pointHoverRadius: 10
          },
          {
            label: "モチベーション 🔥",
            data: chart_data.map { |d| d[:motivation] },
            backgroundColor: "rgba(255, 165, 0, 0.1)",
            borderColor: "rgba(255, 165, 0, 1)",
            borderWidth: 3,
            fill: false,
            tension: 0.3,
            pointBackgroundColor: "rgba(255, 165, 0, 1)",
            pointBorderColor: "#fff",
            pointBorderWidth: 3,
            pointRadius: 6,
            pointHoverRadius: 10
          },
          {
            label: "進捗 🌱",
            data: chart_data.map { |d| d[:progress] },
            backgroundColor: "rgba(34, 197, 94, 0.1)",
            borderColor: "rgba(34, 197, 94, 1)",
            borderWidth: 3,
            fill: false,
            tension: 0.3,
            pointBackgroundColor: "rgba(34, 197, 94, 1)",
            pointBorderColor: "#fff",
            pointBorderWidth: 3,
            pointRadius: 6,
            pointHoverRadius: 10
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: "index"
        },
        plugins: {
          title: {
            display: true,
            text: chart_data.length > 1 ? title_text : "記録を続けて推移を確認しよう！",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            position: "top"
          },
          tooltip: {
            backgroundColor: "rgba(255, 255, 255, 0.95)",
            titleColor: "#333",
            bodyColor: "#666",
            borderColor: "#ddd",
            borderWidth: 1,
            cornerRadius: 8,
            displayColors: true
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 6,
            grid: {
              color: "rgba(0, 0, 0, 0.1)",
              drawBorder: false
            },
            ticks: {
              stepSize: 1,
              callback: "function(value) { return value <= 5 ? 'Lv.' + value : ''; }"
            },
            title: {
              display: true,
              text: "レベル"
            }
          },
          x: {
            grid: {
              color: "rgba(0, 0, 0, 0.05)",
              drawBorder: false
            },
            title: {
              display: true,
              text: "記録日"
            }
          }
        },
        elements: {
          point: {
            hoverRadius: 10
          },
          line: {
            spanGaps: true
          }
        }
      }
    }
  end

  def build_monthly_posts_chart
    monthly_data = current_user.diaries
                               .group_by { |diary| diary.date.beginning_of_month }
                               .transform_values(&:count)
                               .sort_by { |month, _count| month }
                               .last(12) # 直近12ヶ月

    {
      type: "bar",
      data: {
        labels: monthly_data.map { |month, _count| month.strftime("%Y年%m月") },
        datasets: [{
          label: "投稿数",
          data: monthly_data.map { |_month, count| count },
          backgroundColor: "rgba(153, 102, 255, 0.6)",
          borderColor: "rgba(153, 102, 255, 1)",
          borderWidth: 1,
          borderRadius: 4,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "月別投稿数",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: "rgba(0, 0, 0, 0.1)"
            },
            ticks: {
              stepSize: 1
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    }
  end

  def build_achievement_gauge_chart
    # 今月の進捗レベル4-5の達成率を計算
    current_month_start = Date.current.beginning_of_month
    current_month_end = Date.current.end_of_month

    month_diaries = current_user.diaries.where(date: current_month_start..current_month_end)
                                .includes(diary_answers: [:question, :answer])

    if month_diaries.any?
      progress_levels = month_diaries.map { |diary| extract_answer_level(diary, :progress) }.compact
      achievement_count = progress_levels.count { |level| level >= 4 }
      achievement_rate = (achievement_count.to_f / progress_levels.length * 100).round(1)
    else
      achievement_rate = 0
    end

    {
      type: "doughnut",
      data: {
        labels: %w[達成 未達成],
        datasets: [{
          data: [achievement_rate, 100 - achievement_rate],
          backgroundColor: [
            "rgba(34, 197, 94, 0.8)",
            "rgba(229, 231, 235, 0.8)"
          ],
          borderColor: [
            "rgba(34, 197, 94, 1)",
            "rgba(156, 163, 175, 1)"
          ],
          borderWidth: 2,
          cutout: "70%"
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "今月の目標達成率",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            position: "bottom"
          },
          tooltip: {
            callbacks: {
              label: "function(context) { return context.label + ': ' + context.parsed + '%'; }"
            }
          }
        }
      }
    }
  end

  def build_mood_progress_correlation_chart
    # 過去3ヶ月のデータで相関を分析
    diaries = current_user.diaries.where(date: 3.months.ago..Date.current)
                          .includes(diary_answers: [:question, :answer])

    scatter_data = diaries.map do |diary|
      mood = extract_answer_level(diary, :mood)
      progress = extract_answer_level(diary, :progress)

      next unless mood && progress

      {
        x: mood,
        y: progress,
        date: diary.date.strftime("%m/%d")
      }
    end.compact

    {
      type: "scatter",
      data: {
        datasets: [{
          label: "気分 × 進捗の関係",
          data: scatter_data,
          backgroundColor: "rgba(147, 51, 234, 0.6)",
          borderColor: "rgba(147, 51, 234, 1)",
          borderWidth: 2,
          pointRadius: 6,
          pointHoverRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "気分と進捗の相関関係",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            position: "top"
          },
          tooltip: {
            backgroundColor: "rgba(255, 255, 255, 0.95)",
            titleColor: "#333",
            bodyColor: "#666",
            borderColor: "#ddd",
            borderWidth: 1,
            cornerRadius: 8,
            callbacks: {
              title: "function(context) { return context[0].raw.date + 'の記録'; }",
              label: "function(context) { return '気分: Lv.' + context.parsed.x + ', 進捗: Lv.' + context.parsed.y; }"
            }
          }
        },
        scales: {
          x: {
            type: "linear",
            position: "bottom",
            min: 1,
            max: 6,
            title: {
              display: true,
              text: "気分レベル"
            },
            ticks: {
              stepSize: 1,
              callback: "function(value) { return value <= 5 ? value : ''; }"
            }
          },
          y: {
            min: 1,
            max: 6,
            title: {
              display: true,
              text: "進捗レベル"
            },
            ticks: {
              stepSize: 1,
              callback: "function(value) { return value <= 5 ? value : ''; }"
            }
          }
        }
      }
    }
  end

  def build_distribution_chart
    # パラメータから期間を取得（デフォルト1ヶ月）
    months_back = (params[:distribution_months]&.to_i || 1).clamp(1, 12)
    start_date = months_back.months.ago.to_date
    
    # 指定期間のデータを取得
    period_diaries = current_user.diaries.where(date: start_date..Date.current)
                                .includes(diary_answers: [:question, :answer])

    # 各レベルの出現回数を計算
    mood_distribution = calculate_level_distribution(period_diaries, :mood)
    motivation_distribution = calculate_level_distribution(period_diaries, :motivation)
    progress_distribution = calculate_level_distribution(period_diaries, :progress)
    
    # タイトルを期間に応じて動的に設定
    period_text = months_back == 1 ? "直近1ヶ月" : "過去#{months_back}ヶ月間"

    {
      type: "bar",
      data: {
        labels: %w[レベル1 レベル2 レベル3 レベル4 レベル5],
        datasets: [
          {
            label: "気分",
            data: mood_distribution,
            backgroundColor: "rgba(255, 99, 132, 0.6)",
            borderColor: "rgba(255, 99, 132, 1)",
            borderWidth: 1
          },
          {
            label: "モチベーション",
            data: motivation_distribution,
            backgroundColor: "rgba(255, 165, 0, 0.6)",
            borderColor: "rgba(255, 165, 0, 1)",
            borderWidth: 1
          },
          {
            label: "進捗",
            data: progress_distribution,
            backgroundColor: "rgba(34, 197, 94, 0.6)",
            borderColor: "rgba(34, 197, 94, 1)",
            borderWidth: 1
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "各項目のレベル分布（#{period_text}）",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            position: "top"
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: "rgba(0, 0, 0, 0.1)"
            },
            ticks: {
              stepSize: 1
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    }
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
    (1..5).map { |level| levels.count(level) }
  end

  def calculate_average_for_week(week_diaries, identifier)
    levels = week_diaries.map { |diary| extract_answer_level(diary, identifier) }.compact
    return 0 if levels.empty?

    levels.sum.to_f / levels.length
  end

  def build_learning_intensity_heatmap
    # 過去半年間の学習強度ヒートマップ（縦：曜日、横：週）
    start_date = 180.days.ago.to_date
    end_date = Date.current

    # 日記データを取得
    diaries_data = current_user.diaries.where(date: start_date..end_date)
                               .includes(diary_answers: [:question, :answer])
                               .group_by(&:date)

    # 最初の日曜日を計算
    first_sunday = start_date - start_date.wday.days

    # 週数を計算（約26週間）
    total_days = (end_date - first_sunday).to_i + 1
    weeks_count = (total_days / 7.0).ceil

    # 曜日別にデータを整理（縦軸）
    weekday_data = {}
    (0..6).each do |wday|
      weekday_data[wday] = []
    end

    # 各週のデータを処理
    (0...weeks_count).each do |week_index|
      (0..6).each do |wday|
        date = first_sunday + ((week_index * 7) + wday).days

        if date <= end_date
          diary = diaries_data[date]&.first
          intensity = calculate_learning_intensity(diary)

          weekday_data[wday] << {
            date: date,
            intensity: intensity,
            week_index: week_index,
            is_future: date > Date.current,
            is_in_range: date.between?(start_date, end_date)
          }
        else
          # 範囲外の日は空データ
          weekday_data[wday] << {
            date: date,
            intensity: 0,
            week_index: week_index,
            is_future: true,
            is_in_range: false
          }
        end
      end
    end

    {
      type: "custom_heatmap",
      data: {
        weekday_data: weekday_data,
        weeks_count: weeks_count,
        weekday_labels: %w[日 月 火 水 木 金 土],
        start_date: first_sunday,
        end_date: end_date
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "学習強度ヒートマップ（直近半年）",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            display: false
          }
        }
      }
    }
  end

  def calculate_learning_intensity(diary)
    return 0 unless diary

    mood = extract_answer_level(diary, :mood) || 0
    motivation = extract_answer_level(diary, :motivation) || 0
    progress = extract_answer_level(diary, :progress) || 0

    # 総合強度を計算（0-15の範囲）
    total_intensity = mood + motivation + progress

    # 0-4のスケールに正規化
    (total_intensity / 15.0 * 4).round(1)
  end

  def build_habit_calendar_chart
    # 習慣継続カレンダー（今月のカレンダー表示）
    start_date = Date.current.beginning_of_month
    end_date = Date.current.end_of_month

    # 今月の日記データを取得
    month_diaries = current_user.diaries.where(date: start_date..end_date)
                                .includes(diary_answers: [:question, :answer])
                                .index_by(&:date)

    # カレンダーのグリッドを作成
    calendar_weeks = []
    current_week = []

    # 月初の週の調整（日曜日から開始）
    first_sunday = start_date - start_date.wday.days

    # 最大6週間分（42日）をカバー
    (0..41).each do |days_offset|
      date = first_sunday + days_offset.days

      diary = month_diaries[date]
      has_record = diary.present?
      is_current_month = date.month == Date.current.month
      is_today = date == Date.current

      # 学習強度も計算
      intensity = has_record ? calculate_learning_intensity(diary) : 0

      current_week << {
        date: date,
        day: date.day,
        has_record: has_record,
        is_current_month: is_current_month,
        is_today: is_today,
        intensity: intensity,
        weekday: date.strftime("%a")
      }

      # 週末（土曜日）に達したら週を完成
      if date.saturday?
        calendar_weeks << current_week
        current_week = []
      end
    end

    # 最後の週が未完成の場合は追加
    calendar_weeks << current_week unless current_week.empty?

    {
      type: "custom_calendar",
      data: {
        weeks: calendar_weeks,
        month: Date.current.strftime("%Y年%m月"),
        weekdays: %w[日 月 火 水 木 金 土]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "#{Date.current.strftime('%Y年%m月')} 習慣継続カレンダー",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            display: false
          }
        }
      }
    }
  end

  def build_weekday_pattern_chart
    # パラメータから期間を取得（デフォルト1ヶ月）
    months_back = (params[:weekday_months]&.to_i || 1).clamp(1, 12)
    start_date = months_back.months.ago.to_date
    
    # 指定期間のデータで曜日別パターンを分析
    diaries = current_user.diaries.where(date: start_date..Date.current)
                          .includes(diary_answers: [:question, :answer])

    # 曜日別にデータをグループ化
    weekday_data = {}
    (0..6).each do |wday|
      weekday_diaries = diaries.select { |diary| diary.date.wday == wday }

      if weekday_diaries.any?
        mood_levels = weekday_diaries.map { |diary| extract_answer_level(diary, :mood) }.compact
        motivation_levels = weekday_diaries.map { |diary| extract_answer_level(diary, :motivation) }.compact
        progress_levels = weekday_diaries.map { |diary| extract_answer_level(diary, :progress) }.compact

        weekday_data[wday] = {
          mood: mood_levels.any? ? (mood_levels.sum.to_f / mood_levels.length).round(1) : 0,
          motivation: motivation_levels.any? ? (motivation_levels.sum.to_f / motivation_levels.length).round(1) : 0,
          progress: progress_levels.any? ? (progress_levels.sum.to_f / progress_levels.length).round(1) : 0,
          count: weekday_diaries.length
        }
      else
        weekday_data[wday] = { mood: 0, motivation: 0, progress: 0, count: 0 }
      end
    end

    # 月曜スタートの曜日順序 (1=月曜～0=日曜)
    weekday_order = [1, 2, 3, 4, 5, 6, 0]
    weekday_names = %w[月 火 水 木 金 土 日]

    # チャートに渡すデータに記録数情報も含める
    chart_data_with_counts = weekday_order.map.with_index do |wday, index|
      {
        mood: weekday_data[wday][:mood],
        motivation: weekday_data[wday][:motivation],
        progress: weekday_data[wday][:progress],
        count: weekday_data[wday][:count],
        day_name: weekday_names[index]
      }
    end

    # タイトルを期間に応じて動的に設定
    period_text = months_back == 1 ? "直近1ヶ月" : "過去#{months_back}ヶ月間"

    {
      type: "bar",
      data: {
        labels: weekday_names,
        datasets: [
          {
            label: "気分 😊",
            data: chart_data_with_counts.map { |d| d[:mood] },
            backgroundColor: "rgba(255, 99, 132, 0.8)",
            borderColor: "rgba(255, 99, 132, 1)",
            borderWidth: 1,
            borderRadius: 4,
            borderSkipped: false,
            counts: chart_data_with_counts.map { |d| d[:count] }
          },
          {
            label: "モチベーション 🔥",
            data: chart_data_with_counts.map { |d| d[:motivation] },
            backgroundColor: "rgba(255, 165, 0, 0.8)",
            borderColor: "rgba(255, 165, 0, 1)",
            borderWidth: 1,
            borderRadius: 4,
            borderSkipped: false,
            counts: chart_data_with_counts.map { |d| d[:count] }
          },
          {
            label: "進捗 🌱",
            data: chart_data_with_counts.map { |d| d[:progress] },
            backgroundColor: "rgba(34, 197, 94, 0.8)",
            borderColor: "rgba(34, 197, 94, 1)",
            borderWidth: 1,
            borderRadius: 4,
            borderSkipped: false,
            counts: chart_data_with_counts.map { |d| d[:count] }
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "曜日別パフォーマンスパターン（#{period_text}）",
            font: { size: 16, weight: "bold" }
          },
          legend: {
            position: "top"
          },
          tooltip: {
            backgroundColor: "rgba(255, 255, 255, 0.95)",
            titleColor: "#333",
            bodyColor: "#666",
            borderColor: "#ddd",
            borderWidth: 1,
            cornerRadius: 8
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 6,
            grid: {
              color: "rgba(0, 0, 0, 0.1)",
              drawBorder: false
            },
            ticks: {
              stepSize: 1,
              callback: "function(value) { return value <= 5 ? 'Lv.' + value : ''; }"
            },
            title: {
              display: true,
              text: "パフォーマンスレベル"
            }
          },
          x: {
            grid: {
              display: false
            },
            title: {
              display: true,
              text: "曜日"
            }
          }
        },
        interaction: {
          intersect: false,
          mode: "index"
        }
      }
    }
  end
end
