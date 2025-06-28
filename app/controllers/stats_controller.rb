class StatsController < ApplicationController
  def index
    @daily_trends_chart = build_daily_trends_chart
    @monthly_posts_chart = build_monthly_posts_chart
    @today_summary_chart = build_today_summary_chart
    @distribution_chart = build_distribution_chart
  end

  private

  def build_daily_trends_chart
    # 実際に日記がある日のみのデータを取得
    diaries = current_user.diaries.where(date: 30.days.ago..Time.current)
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
      type: 'line',
      data: {
        labels: chart_data.map { |d| d[:date].strftime('%m/%d') },
        datasets: [
          {
            label: '気分 😊',
            data: chart_data.map { |d| d[:mood] },
            backgroundColor: 'rgba(255, 99, 132, 0.1)',
            borderColor: 'rgba(255, 99, 132, 1)',
            borderWidth: 3,
            fill: false,
            tension: 0.3,
            pointBackgroundColor: 'rgba(255, 99, 132, 1)',
            pointBorderColor: '#fff',
            pointBorderWidth: 3,
            pointRadius: 6,
            pointHoverRadius: 10
          },
          {
            label: 'モチベーション 🔥',
            data: chart_data.map { |d| d[:motivation] },
            backgroundColor: 'rgba(255, 165, 0, 0.1)',
            borderColor: 'rgba(255, 165, 0, 1)',
            borderWidth: 3,
            fill: false,
            tension: 0.3,
            pointBackgroundColor: 'rgba(255, 165, 0, 1)',
            pointBorderColor: '#fff',
            pointBorderWidth: 3,
            pointRadius: 6,
            pointHoverRadius: 10
          },
          {
            label: '進捗 🌱',
            data: chart_data.map { |d| d[:progress] },
            backgroundColor: 'rgba(34, 197, 94, 0.1)',
            borderColor: 'rgba(34, 197, 94, 1)',
            borderWidth: 3,
            fill: false,
            tension: 0.3,
            pointBackgroundColor: 'rgba(34, 197, 94, 1)',
            pointBorderColor: '#fff',
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
          mode: 'index'
        },
        plugins: {
          title: {
            display: true,
            text: chart_data.length > 1 ? '日記記録の推移' : '記録を続けて推移を確認しよう！',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            position: 'top'
          },
          tooltip: {
            backgroundColor: 'rgba(255, 255, 255, 0.95)',
            titleColor: '#333',
            bodyColor: '#666',
            borderColor: '#ddd',
            borderWidth: 1,
            cornerRadius: 8,
            displayColors: true,
            callbacks: {
              title: "function(context) { return context[0].label + 'の記録'; }",
              label: "function(context) { return context.dataset.label + ': レベル' + context.parsed.y; }"
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 5,
            grid: {
              color: 'rgba(0, 0, 0, 0.1)',
              drawBorder: false
            },
            ticks: {
              stepSize: 1,
              callback: "function(value) { return 'Lv.' + value; }"
            },
            title: {
              display: true,
              text: 'レベル'
            }
          },
          x: {
            grid: {
              color: 'rgba(0, 0, 0, 0.05)',
              drawBorder: false
            },
            title: {
              display: true,
              text: '記録日'
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
      type: 'bar',
      data: {
        labels: monthly_data.map { |month, _count| month.strftime('%Y年%m月') },
        datasets: [{
          label: '投稿数',
          data: monthly_data.map { |_month, count| count },
          backgroundColor: 'rgba(153, 102, 255, 0.6)',
          borderColor: 'rgba(153, 102, 255, 1)',
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
            text: '月別投稿数',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
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

  def build_today_summary_chart
    today_diary = current_user.diaries.find_by(date: Date.current)
    
    if today_diary
      mood = extract_answer_level(today_diary, :mood) || 0
      motivation = extract_answer_level(today_diary, :motivation) || 0
      progress = extract_answer_level(today_diary, :progress) || 0
    else
      mood = motivation = progress = 0
    end

    {
      type: 'doughnut',
      data: {
        labels: ['気分', 'モチベーション', '進捗'],
        datasets: [{
          data: [mood, motivation, progress],
          backgroundColor: [
            'rgba(255, 99, 132, 0.8)',
            'rgba(255, 165, 0, 0.8)',
            'rgba(34, 197, 94, 0.8)'
          ],
          borderColor: [
            'rgba(255, 99, 132, 1)',
            'rgba(255, 165, 0, 1)',
            'rgba(34, 197, 94, 1)'
          ],
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: today_diary ? '今日の状態' : '今日はまだ記録なし',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            position: 'bottom'
          }
        }
      }
    }
  end

  def build_distribution_chart
    all_diaries = current_user.diaries.includes(diary_answers: [:question, :answer])
    
    # 各レベルの出現回数を計算
    mood_distribution = calculate_level_distribution(all_diaries, :mood)
    motivation_distribution = calculate_level_distribution(all_diaries, :motivation)
    progress_distribution = calculate_level_distribution(all_diaries, :progress)

    {
      type: 'bar',
      data: {
        labels: ['レベル1', 'レベル2', 'レベル3', 'レベル4', 'レベル5'],
        datasets: [
          {
            label: '気分',
            data: mood_distribution,
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
            borderWidth: 1
          },
          {
            label: 'モチベーション',
            data: motivation_distribution,
            backgroundColor: 'rgba(255, 165, 0, 0.6)',
            borderColor: 'rgba(255, 165, 0, 1)',
            borderWidth: 1
          },
          {
            label: '進捗',
            data: progress_distribution,
            backgroundColor: 'rgba(34, 197, 94, 0.6)',
            borderColor: 'rgba(34, 197, 94, 1)',
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
            text: '各項目のレベル分布',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            position: 'top'
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
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
end
