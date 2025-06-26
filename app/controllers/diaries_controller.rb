class DiariesController < ApplicationController
  before_action :set_diary, only: [:show, :edit, :update, :destroy]

  def index
    @diaries = current_user.diaries.order(date: :desc)
  end

  def show; end

  def new
    @diary = Diary.new
    @questions = Question.all
    @date = params[:date] || Date.current
  end

  def edit
    @questions = Question.all
    # 現在の選択状態を取得
    @selected_answers = {}
    @diary.diary_answers.includes(:question).each do |diary_answer|
      @selected_answers[diary_answer.question.identifier] = diary_answer.answer_id.to_s
    end
  end

  def create
    @diary = current_user.diaries.build(diary_params)
    if @diary.save
      # DiaryAnswerの保存
      if params[:diary_answers].present?

        diary_answer_params.each do |question_identifier, answer_id|
          question = Question.find_by(identifier: question_identifier)
          if question && answer_id.present?
            diary_answer = @diary.diary_answers.create(question: question, answer_id: answer_id)
          end
        end

      end

      # TIL候補の生成
      if @diary.notes.present?

        begin
          client = OpenaiService.new
          til_candidates = client.generate_til(@diary.notes)
          til_candidates.each_with_index do |content, index|
            @diary.til_candidates.create(content: content, index: index)
          end
          redirect_to edit_diary_path(@diary), notice: "日記を作成しました。TILを選択してください。"
        rescue StandardError => e
          redirect_to diaries_path, notice: "日記を作成しました（TIL生成でエラーが発生しました）"
        end

      else
        redirect_to diaries_path, notice: "日記を作成しました"
      end
    else
      @questions = Question.all
      # フォームで選択された気分データを保持
      @selected_answers = params[:diary_answers] || {}
      render :new
    end
  end

  def update
    if @diary.update(diary_update_params)
      # DiaryAnswerの更新
      if params[:diary_answers].present?

        # 既存のDiaryAnswerを削除
        @diary.diary_answers.destroy_all

        # 新しいDiaryAnswerを作成
        diary_answer_params.each do |question_identifier, answer_id|
          question = Question.find_by(identifier: question_identifier)

          @diary.diary_answers.create(question: question, answer_id: answer_id) if question && answer_id.present?
        end
      end

      # TIL候補の再生成（メモが更新された場合）
      notes_changed = @diary.notes_changed?
      if @diary.notes.present? && notes_changed
        begin
          # 既存のTIL候補を削除
          @diary.til_candidates.destroy_all

          client = OpenaiService.new
          til_candidates = client.generate_til(@diary.notes)
          til_candidates.each_with_index do |content, index|
            @diary.til_candidates.create(content: content, index: index)
          end
        rescue StandardError
        end
      end

      if params[:push_to_github] == "1"
        client = GithubService.new(current_user)
        client.push_til(@diary)
      end

      redirect_to diary_path(@diary), notice: "日記を更新しました"
    else
      @questions = Question.all
      @selected_answers = params[:diary_answers] || {}
      render :edit
    end
  end

  def destroy
    if @diary.destroy
      redirect_to diaries_path, status: :see_other, notice: "日記を削除しました"
    else
      redirect_to diaries_path, alert: "日記の削除に失敗しました"
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
    params.require(:diary).permit(:til_text, :notes, :is_public)
  end

  def diary_answer_params
    # 動的にQuestionのidentifierを取得してpermitする
    question_identifiers = Question.pluck(:identifier).map(&:to_sym)
    Rails.logger.debug "Question identifiers: #{question_identifiers}"

    if params[:diary_answers].present?
      permitted_params = params.permit(diary_answers: question_identifiers)[:diary_answers]
      Rails.logger.debug "Permitted diary_answer_params: #{permitted_params.inspect}"
      permitted_params || {}
    else
      Rails.logger.debug "No diary_answers parameter found"
      {}
    end
  end
end
