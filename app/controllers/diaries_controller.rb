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
    @existing_diary = current_user.diaries.find_by(date: @date)
  end

  def edit
    @questions = Question.all
    @selected_answers = @diary.diary_answers.includes(:question).each_with_object({}) do |diary_answer, hash|
      hash[diary_answer.question.identifier] = diary_answer.answer_id.to_s
    end
  end

  def create
    @diary = current_user.diaries.build(diary_params)
    if @diary.save
      diary_service.create_diary_answers(diary_answer_params)
      skip_ai = params[:skip_ai_generation] == "true" || params[:use_ai_generation] != "1"
      result = diary_service.handle_til_generation_and_redirect(skip_ai_generation: skip_ai)
      redirect_to result[:redirect_to], notice: result[:notice]
    else
      handle_creation_error
    end
  end

  def update
    if @diary.update(diary_update_params)
      diary_service.update_diary_answers(diary_answer_params)
      diary_service.regenerate_til_candidates_if_needed if params[:regenerate_ai] == "1"
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
    redirect_path = result[:requires_reauth] ? "/users/auth/github" : diary_path(@diary)
    flash_type = result[:success] ? :notice : :alert

    redirect_to redirect_path, flash_type => result[:message]
  end

  def increment_seed
    seed_service = SeedService.new(current_user).increment_daily_seed

    respond_to do |format|
      format.turbo_stream do
        render_seed_turbo_stream(seed_service)
      end
      format.html { redirect_to diaries_path, notice: seed_service.html_message_for_increment }
    end
  end

  def share_on_x
    @diary = current_user.diaries.find(params[:diary_id]) if params[:diary_id]
    seed_service = SeedService.new(current_user).increment_share_seed

    respond_to do |format|
      format.turbo_stream do
        render_seed_turbo_stream(seed_service)
      end
      format.html { redirect_to diary_path(@diary), flash_type_for_seed(seed_service) => seed_service.message }
      format.json { render json: json_response_for_seed(seed_service) }
    end
  end

  def search_by_date
    date = Date.parse(params[:date])
    diary = current_user.diaries.find_by(date: date)

    if diary
      render json: { diary_id: diary.id }
    else
      render json: { diary_id: nil }
    end
  rescue Date::Error
    render json: { error: "Invalid date format" }, status: 400
  end

  private

  def render_seed_turbo_stream(seed_service)
    if seed_service.success
      render turbo_stream: [
        turbo_stream.update("flash-messages", partial: "shared/flash", locals: {
                              flash: { notice: seed_service.message }
                            }),
        turbo_stream.update("seed-count", current_user.seed_count),
        turbo_stream.update("watering-button", partial: "shared/watering")
      ]
    else
      render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash", locals: {
                                                 flash: { alert: seed_service.message }
                                               })
    end
  end

  def flash_type_for_seed(seed_service)
    seed_service.success ? :notice : :alert
  end

  def json_response_for_seed(seed_service)
    if seed_service.success
      { success: true, seed_count: current_user.seed_count }
    else
      { success: false, message: seed_service.message }
    end
  end

  def set_diary
    @diary = current_user.diaries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diaries_path, alert: "指定された日記は見つかりません。"
  end

  def set_diary_for_show
    @diary = if user_signed_in?
               current_user.diaries.find_by(id: params[:id]) || public_diary_scope.find(params[:id])
             else
               public_diary_scope.find(params[:id])
             end
  rescue ActiveRecord::RecordNotFound
    redirect_to user_signed_in? ? diaries_path : root_path, alert: "指定された日記は見つかりません。"
  end

  def public_diary_scope
    Diary.public_diaries.includes(:user, :diary_answers, :til_candidates)
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
    question_identifiers = Question.pluck(:identifier).map(&:to_sym)
    params[:diary_answers].present? ? params.permit(diary_answers: question_identifiers)[:diary_answers] || {} : {}
  end

  def handle_creation_error
    handle_error_data(diary_service.handle_creation_error(Question.all, params, current_user), :new)
  end

  def handle_update_error
    handle_error_data(diary_service.handle_update_error(Question.all), :edit)
  end

  def handle_error_data(error_data, view)
    @questions, @selected_answers = error_data.values_at(:questions, :selected_answers)
    @date = error_data[:date] if view == :new
    @existing_diary_for_error = error_data[:existing_diary_for_error] if view == :new
    flash.now[:alert] = error_data[:flash_message] if error_data[:flash_message]
    render view
  end

  def check_github_repository_status
    return unless current_user.github_repo_configured? && !current_user.verify_github_repository?

    Rails.logger.info "Repository #{current_user.github_repo_name} not found for user #{current_user.id}"
    flash.now[:alert] = "設定されたGitHubリポジトリが見つかりません。GitHub設定を確認してください。"
  end
end
