class StatsController < ApplicationController
  def index
    diaries = current_user.diaries.where(date: 30.days.ago..Time.current).order(date: :asc)
    @chart_data = build_chart_data(diaries)
  end

  private

  def build_chart_data(diaries)
    {
      labels: diaries.map(&:date),
      datasets: [
        build_mood_dataset(diaries),
        build_motivation_dataset(diaries),
        build_progress_dataset(diaries)
      ]
    }
  end

  def build_mood_dataset(diaries)
    {
      label: "今日の気分",
      data: extract_answer_data(diaries, :mood),
      backgroundColor: "rgba(255, 99, 132, 0.2)",
      borderColor: "rgba(255, 99, 132, 1)",
      borderWidth: 1
    }
  end

  def build_motivation_dataset(diaries)
    {
      label: "今日のモチベーション",
      data: extract_answer_data(diaries, :motivation),
      backgroundColor: "rgba(54, 162, 235, 0.2)",
      borderColor: "rgba(54, 162, 235, 1)",
      borderWidth: 1
    }
  end

  def build_progress_dataset(diaries)
    {
      label: "目標の進捗",
      data: extract_answer_data(diaries, :progress),
      backgroundColor: "rgba(255, 206, 86, 0.2)",
      borderColor: "rgba(255, 206, 86, 1)",
      borderWidth: 1
    }
  end

  def extract_answer_data(diaries, identifier)
    diaries.map do |diary|
      diary.diary_answers.find_by(question: Question.find_by(identifier: identifier))&.answer&.level
    end
  end
end
