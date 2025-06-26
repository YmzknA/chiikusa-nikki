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
    Rails.logger.debug "=== Diary Creation Debug ==="
    Rails.logger.debug "Raw params: #{params.inspect}"
    Rails.logger.debug "diary_answers params: #{params[:diary_answers].inspect}"
    
    @diary = current_user.diaries.build(diary_params)
    if @diary.save
      Rails.logger.debug "Diary saved with ID: #{@diary.id}"
      
      # DiaryAnswerの保存
      if params[:diary_answers].present?
        Rails.logger.debug "Processing diary answers..."
        diary_answer_params.each do |question_identifier, answer_id|
          Rails.logger.debug "Processing: #{question_identifier} -> #{answer_id}"
          question = Question.find_by(identifier: question_identifier)
          Rails.logger.debug "Found question: #{question.inspect}"
          
          if question && answer_id.present?
            diary_answer = @diary.diary_answers.create(question: question, answer_id: answer_id)
            Rails.logger.debug "Created DiaryAnswer: #{diary_answer.inspect}"
            Rails.logger.debug "Errors: #{diary_answer.errors.full_messages}" if diary_answer.errors.any?
          else
            Rails.logger.debug "Skipped - question not found or answer_id empty"
          end
        end
      else
        Rails.logger.debug "No diary_answers params found"
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
        rescue => e
          Rails.logger.error "OpenAI API Error: #{e.message}"
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
