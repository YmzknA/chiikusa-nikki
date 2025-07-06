class DiariesController < ApplicationController
  include DiaryFiltering
  include SeedManagement
  include GithubIntegration
  include DiaryErrorHandling

  ORIGINAL_NOTES_INDEX = -1

  before_action :authenticate_user!, except: [:show, :public_index]
  before_action :set_diary_for_show, only: [:show]
  before_action :set_diary,
                only: [:edit, :update, :destroy, :upload_to_github, :select_til, :update_til_selection,
                       :reaction_modal_content]

  def index
    @selected_month = params[:month].present? ? params[:month] : "all"
    @diaries = filter_diaries_by_month(
      current_user.diaries.includes(:diary_answers, :til_candidates),
      @selected_month
    ).order(date: :desc, created_at: :desc)
    @available_months = available_months
  end

  def show
    check_github_repository_status if user_signed_in?

    # 他ユーザーの非公開日記へのアクセスを禁止
    unless diary_accessible?
      redirect_to user_signed_in? ? diaries_path : root_path, alert: "この日記にはアクセスできません。"
      return
    end

    @share_content = "🌱#{@diary.date.strftime('%Y年%m月%d日')}のちいくさ日記🌱%0A%0A" \
                     "%23ちいくさ日記%0A%23毎日1分簡単日記%0A&url=#{diary_url(@diary)}"
  end

  def public_index
    @diaries = Diary.public_diaries
                    .includes(user: [], diary_answers: [:answer])
                    .order(date: :desc, created_at: :desc)
                    .limit(20)
  end

  def new
    @diary = Diary.new
    @questions = Question.cached_all
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @existing_diary = current_user.diaries.find_by(date: @date)
  end

  def edit
    @questions = Question.cached_all
    @selected_answers = @diary.diary_answers.includes(:question).each_with_object({}) do |diary_answer, hash|
      hash[diary_answer.question.identifier] = diary_answer.answer_id.to_s
    end
  end

  def create
    @diary = current_user.diaries.build(diary_params)
    if @diary.save
      diary_service.create_diary_answers(diary_answer_params)
      skip_ai = params[:skip_ai_generation] == "true" || params[:use_ai_generation] != "1"
      diary_type = params[:diary_type].presence || "personal"
      result = diary_service.handle_til_generation_and_redirect(skip_ai_generation: skip_ai, diary_type: diary_type)
      redirect_to result[:redirect_to], notice: result[:notice]
    else
      handle_creation_error
    end
  end

  def update
    if @diary.update(diary_update_params)
      diary_service.update_diary_answers(diary_answer_params)
      if params[:regenerate_ai] == "1"
        diary_type = params[:diary_type].presence || "personal"
        result = diary_service.regenerate_til_candidates_if_needed(diary_type: diary_type)
        redirect_to result ? select_til_diary_path(@diary) : diary_path(@diary),
                    notice: result ? "TILを再生成しました。新しいTILを選択してください。" : "日記を更新しました"
      else
        redirect_to diary_path(@diary), notice: "日記を更新しました"
      end
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

  def select_til
    @questions = Question.cached_all
    return if @diary.til_candidates.any?

    redirect_to diary_path(@diary), alert: "TIL候補が存在しません。"
  end

  def update_til_selection
    return redirect_with_alert("TILを選択してください。") unless til_selection_params[:selected_til_index].present?

    selected_index = til_selection_params[:selected_til_index].to_i

    return unless process_til_selection?(selected_index)

    ActiveRecord::Base.transaction do
      @diary.save!
      redirect_to diary_path(@diary), notice: "TILを選択しました。"
    end
  rescue ActiveRecord::RecordInvalid
    redirect_with_alert("TILの選択に失敗しました。もう一度お試しください。")
  end

  def reaction_modal_content
    render partial: "shared/reaction_modal_content", locals: { diary: @diary, current_user: current_user }
  end

  private

  def process_til_selection?(selected_index)
    if selected_index == ORIGINAL_NOTES_INDEX
      @diary.selected_til_index = nil
      @diary.til_text = nil
      true
    elsif selected_index >= 0
      process_til_candidate_selection?(selected_index)
    else
      redirect_with_alert("不正な選択値です。")
      false
    end
  end

  def process_til_candidate_selection?(selected_index)
    candidate = @diary.til_candidates.find_by(index: selected_index)
    unless candidate
      redirect_with_alert("不正なTIL選択です。もう一度選択してください。")
      return false
    end

    @diary.selected_til_index = selected_index
    @diary.til_text = candidate.content
    true
  end

  def redirect_with_alert(message)
    redirect_to select_til_diary_path(@diary), alert: message
  end

  # AuthorizationHelperのresource_owner?をヘルパーメソッドとして使用
  helper_method :resource_owner?

  # 日記にアクセス可能かどうかを判定
  def diary_accessible?
    return false unless @diary.present?

    # 公開日記は誰でもアクセス可能
    return true if @diary.is_public?

    # 非公開日記は所有者のみアクセス可能
    resource_owner?(@diary)
  end

  def set_diary
    @diary = current_user.diaries.includes(:til_candidates, diary_answers: :answer).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diaries_path, alert: "指定された日記は見つかりません。"
  end

  def set_diary_for_show
    @diary = if user_signed_in?
               current_user.diaries.includes(:user, :diary_answers, :til_candidates)
                           .find_by(id: params[:id]) || public_diary_scope.find(params[:id])
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
    question_identifiers = Question.cached_identifiers
    params[:diary_answers].present? ? params.permit(diary_answers: question_identifiers)[:diary_answers] || {} : {}
  end

  def til_selection_params
    params.permit(:selected_til_index)
  end
end
