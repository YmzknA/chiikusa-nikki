class DiaryService
  def initialize(diary, user = nil)
    @diary = diary
    @user = user || diary.user
  end

  def create_diary_answers(diary_answer_params)
    return unless diary_answer_params.present?

    diary_answer_params.each do |question_identifier, answer_id|
      question = Question.find_by(identifier: question_identifier)
      @diary.diary_answers.create(question: question, answer_id: answer_id) if question && answer_id.present?
    end
  end

  def update_diary_answers(diary_answer_params)
    return unless diary_answer_params.present?

    @diary.diary_answers.destroy_all
    diary_answer_params.each do |question_identifier, answer_id|
      question = Question.find_by(identifier: question_identifier)
      @diary.diary_answers.create(question: question, answer_id: answer_id) if question && answer_id.present?
    end
  end

  def handle_til_generation_and_redirect
    if @diary.notes.present?
      generate_til_candidates_and_redirect
    else
      { redirect_to: [:diary, @diary], notice: "日記を作成しました" }
    end
  end

  def generate_til_candidates_and_redirect
    openai_service = OpenaiService.new
    til_candidates = openai_service.generate_tils(@diary.notes)

    til_candidates.each_with_index do |content, index|
      @diary.til_candidates.create(content: content, index: index)
    end

    { redirect_to: [:edit, @diary], notice: "日記を作成しました。続いて生成されたTIL を選択してください。" }
  rescue StandardError => e
    Rails.logger.info("Error generating TIL candidates: #{e.message}")
    { redirect_to: :diaries, notice: "日記を作成しました（TIL生成でエラーが発生しました）" }
  end

  def regenerate_til_candidates_if_needed(notes_changed, til_text_changed)
    return unless notes_changed || til_text_changed
    return if @diary.notes.blank?

    # Clear existing candidates and generate new ones
    @diary.til_candidates.destroy_all
    openai_service = OpenaiService.new
    til_candidates = openai_service.generate_tils(@diary.notes)

    til_candidates.each_with_index do |content, index|
      @diary.til_candidates.create(content: content, index: index)
    end
  rescue StandardError => e
    Rails.logger.error("Error regenerating TIL candidates: #{e.message}")
  end

  def handle_creation_error(questions, params, current_user)
    selected_answers = params[:diary_answers] || {}
    date = @diary.date || params[:diary][:date] || Date.current
    existing_diary = current_user.diaries.find_by(date: date)

    if @diary.errors[:date].any? && existing_diary
      flash_message = "#{@diary.date.strftime('%Y年%m月%d日')}の日記は既に作成されています。同じ日に複数の日記は作成できません。"
      {
        questions: questions,
        selected_answers: selected_answers,
        date: date,
        existing_diary_for_error: existing_diary,
        flash_message: flash_message
      }
    else
      {
        questions: questions,
        selected_answers: selected_answers,
        date: date,
        existing_diary_for_error: nil,
        flash_message: nil
      }
    end
  end

  def handle_update_error(questions)
    selected_answers = {}
    @diary.diary_answers.includes(:question).each do |diary_answer|
      selected_answers[diary_answer.question.identifier] = diary_answer.answer_id.to_s
    end

    {
      questions: questions,
      selected_answers: selected_answers
    }
  end
end
