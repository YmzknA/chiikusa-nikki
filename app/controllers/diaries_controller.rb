class DiariesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :public_index]
  before_action :set_diary_for_show, only: [:show]
  before_action :set_diary, only: [:edit, :update, :destroy, :upload_to_github]

  def index
    @diaries = current_user.diaries.order(date: :desc)
  end

  def show
    check_github_repository_status if user_signed_in?
  end

  def public_index
    @diaries = Diary.public_diaries.includes(:user, :diary_answers).order(date: :desc).limit(20)
  end

  def new
    @diary = Diary.new
    @questions = Question.all
    @date = params[:date] || Date.current

    # 既存日記のチェック
    @existing_diary = current_user.diaries.find_by(date: @date)
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
      diary_service.create_diary_answers(diary_answer_params)
      result = diary_service.handle_til_generation_and_redirect
      redirect_to result[:redirect_to], notice: result[:notice]
    else
      handle_creation_error
    end
  end

  def update
    if @diary.update(diary_update_params)
      diary_service.update_diary_answers(diary_answer_params)
      notes_changed = @diary.previous_changes.key?("notes")
      til_text_changed = @diary.previous_changes.key?("til_text")
      diary_service.regenerate_til_candidates_if_needed(notes_changed, til_text_changed)
      redirect_to diary_path(@diary), notice: "日記を更新しました"
    else
      handle_update_error
    end
  end

  def destroy
    if @diary.destroy
      redirect_to diaries_path, status: :see_other, notice: "日記を削除しました"
    else
      redirect_to diaries_path, alert: "日記の削除に失敗しました"
    end
  end

  def upload_to_github
    unless @diary.can_upload_to_github?
      redirect_to diary_path(@diary), alert: "GitHubにアップロードできません。リポジトリ設定とTIL選択を確認してください。"
      return
    end

    result = current_user.github_service.push_til(@diary)

    if result[:success]
      redirect_to diary_path(@diary), notice: result[:message]
    elsif result[:requires_reauth]
      redirect_to "/users/auth/github", alert: result[:message]
    elsif result[:rate_limited]
      redirect_to diary_path(@diary), alert: result[:message]
    else
      redirect_to diary_path(@diary), alert: result[:message]
    end
  end

  private

  def set_diary
    @diary = current_user.diaries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diaries_path, alert: "指定された日記は見つかりません。"
  end

  def set_diary_for_show
    if user_signed_in?
      @diary = current_user.diaries.find_by(id: params[:id])
      @diary ||= Diary.public_diaries.includes(:user, :diary_answers, :til_candidates).find(params[:id])
    else
      @diary = Diary.public_diaries.includes(:user, :diary_answers, :til_candidates).find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to user_signed_in? ? diaries_path : root_path, alert: "指定された日記は見つかりません。"
  end

  def diary_service
    @diary_service ||= DiaryService.new(@diary)
  end

  def diary_params
    params.require(:diary).permit(:date, :notes, :is_public)
  end

  def diary_update_params
    params.require(:diary).permit(:til_text, :notes, :is_public, :selected_til_index)
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

  def handle_creation_error
    error_data = diary_service.handle_creation_error(Question.all, params, current_user)
    @questions = error_data[:questions]
    @selected_answers = error_data[:selected_answers]
    @date = error_data[:date]
    @existing_diary_for_error = error_data[:existing_diary_for_error]
    flash.now[:alert] = error_data[:flash_message] if error_data[:flash_message]
    render :new
  end

  def handle_update_error
    error_data = diary_service.handle_update_error(Question.all)
    @questions = error_data[:questions]
    @selected_answers = error_data[:selected_answers]
    render :edit
  end

  def check_github_repository_status
    return unless current_user.github_repo_configured?

    return if current_user.verify_github_repository?

    log_message = "Repository #{current_user.github_repo_name} not found for user #{current_user.id}. " \
                  "Resetting upload status."
    Rails.logger.info log_message
    flash.now[:alert] = "設定されたGitHubリポジトリが見つかりません。GitHub設定を確認してください。"
  end
end
