class DiariesController < ApplicationController
  before_action :require_login

  def new
    @diary = Diary.new
    @questions = Question.all
  end

  def create
    @diary = current_user.diaries.build(diary_params)
    if @diary.save
      # DiaryAnswerの保存
      diary_answer_params.each do |question_identifier, answer_id|
        question = Question.find_by(identifier: question_identifier)
        @diary.diary_answers.create(question: question, answer_id: answer_id)
      end
      redirect_to diaries_path, notice: "日記を作成しました"
    else
      @questions = Question.all
      render :new
    end
  end

  private

  def diary_params
    params.require(:diary).permit(:date, :notes, :is_public)
  end

  def diary_answer_params
    params.require(:diary_answers).permit(:mood, :motivation, :progress)
  end

  def require_login
    unless current_user
      redirect_to root_path, alert: "ログインしてください"
    end
  end
end
