class DiariesController < ApplicationController
  before_action :set_diary, only: [:show, :edit, :update]

  def index
    @diaries = current_user.diaries.order(date: :desc)
  end

  def show; end

  def new
    @diary = Diary.new
    @questions = Question.all
  end

  def edit; end

  def create
    @diary = current_user.diaries.build(diary_params)
    if @diary.save
      # DiaryAnswerの保存
      diary_answer_params.each do |question_identifier, answer_id|
        question = Question.find_by(identifier: question_identifier)
        @diary.diary_answers.create(question: question, answer_id: answer_id)
      end

      # TIL候補の生成
      if @diary.notes.present?
        client = OpenaiService.new
        til_candidates = client.generate_til(@diary.notes)
        til_candidates.each_with_index do |content, index|
          @diary.til_candidates.create(content: content, index: index)
        end
        redirect_to edit_diary_path(@diary), notice: "日記を作成しました。TILを選択してください。"
      else
        redirect_to diaries_path, notice: "日記を作成しました"
      end
    else
      @questions = Question.all
      render :new
    end
  end

  def update
    if @diary.update(diary_update_params)
      if params[:push_to_github] == "1"
        client = GithubService.new(current_user)
        client.push_til(@diary)
      end
      redirect_to diaries_path, notice: "日記を更新しました"
    else
      render :edit
    end
  end

  private

  def set_diary
    @diary = current_user.diaries.find(params[:id])
  end

  def diary_params
    params.require(:diary).permit(:date, :notes, :is_public)
  end

  def diary_update_params
    params.require(:diary).permit(:til_text)
  end

  def diary_answer_params
    params.require(:diary_answers).permit(:mood, :motivation, :progress)
  end
end
