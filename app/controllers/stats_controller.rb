class StatsController < ApplicationController
  def index
    diaries = current_user.diaries.where(date: 30.days.ago..Time.current).order(date: :asc)

    @chart_data = {
      labels: diaries.map(&:date),
      datasets: [
        {
          label: "今日の気分",
          data: diaries.map { |d| d.diary_answers.find_by(question: Question.find_by(identifier: :mood))&.answer&.level },
          backgroundColor: "rgba(255, 99, 132, 0.2)",
          borderColor: "rgba(255, 99, 132, 1)",
          borderWidth: 1
        },
        {
          label: "学習のモチベーション",
          data: diaries.map { |d| d.diary_answers.find_by(question: Question.find_by(identifier: :motivation))&.answer&.level },
          backgroundColor: "rgba(54, 162, 235, 0.2)",
          borderColor: "rgba(54, 162, 235, 1)",
          borderWidth: 1
        },
        {
          label: "学習の進捗",
          data: diaries.map { |d| d.diary_answers.find_by(question: Question.find_by(identifier: :progress))&.answer&.level },
          backgroundColor: "rgba(255, 206, 86, 0.2)",
          borderColor: "rgba(255, 206, 86, 1)",
          borderWidth: 1
        }
      ]
    }
  end
end
