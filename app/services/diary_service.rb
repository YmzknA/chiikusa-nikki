class DiaryService
  def initialize(diary, user = nil)
    @diary = diary
    @user = user || diary.user
  end

  def create_diary_answers(diary_answer_params)
    return unless diary_answer_params.present?

    diary_answers_data = build_validated_answers_data(diary_answer_params)
    DiaryAnswer.insert_all(diary_answers_data) if diary_answers_data.any?
  end

  def update_diary_answers(diary_answer_params)
    return unless diary_answer_params.present?

    ActiveRecord::Base.transaction do
      @diary.diary_answers.destroy_all
      diary_answers_data = build_validated_answers_data(diary_answer_params)
      DiaryAnswer.insert_all(diary_answers_data) if diary_answers_data.any?
    end
  end

  def handle_til_generation_and_redirect(skip_ai_generation: false, diary_type: "personal")
    if @diary.notes.present? && !skip_ai_generation
      generate_til_candidates_and_redirect(diary_type: diary_type)
    else
      { redirect_to: @diary, notice: "日記を作成しました" }
    end
  end

  def generate_til_candidates_and_redirect(diary_type: "personal")
    seed_manager = SeedManager.new(@user)

    unless seed_manager.sufficient_seeds?
      return { redirect_to: @diary,
               notice: "日記を作成しました（#{seed_manager.insufficient_seeds_message}）" }
    end

    # 外部API呼び出しをトランザクション外で実行
    openai_service = AiServiceFactory.create(diary_type)
    
    begin
      til_candidates = openai_service.generate_tils(@diary.notes)
      
      # 外部API成功後、短時間でDB操作のみをトランザクション内で実行
      ActiveRecord::Base.transaction do
        til_candidates.each_with_index do |content, index|
          @diary.til_candidates.create!(content: content, index: index)
        end

        seed_manager.consume_seed!
      end

      { redirect_to: [:select_til, @diary], notice: "日記を作成しました。続いて生成されたTIL を選択してください。" }
    rescue StandardError => e
      # タイムアウトエラーの場合はタネを消費しない
      if AiServiceErrorHandler.timeout_error?(e)
        Rails.logger.warn "TIL generation timeout for user_id: #{@user.id} - seed not consumed"
        { redirect_to: @diary, notice: "日記を作成しました（AI応答がタイムアウトしました。タネは消費されていません）" }
      else
        Rails.logger.error "TIL generation failed for user_id: #{@user.id}"
        Rails.logger.debug "TIL generation error details: #{sanitize_log_message(e.message)}" unless Rails.env.production?
        { redirect_to: @diary, notice: "日記を作成しました（TIL生成でエラーが発生しました）" }
      end
    end
  end

  def regenerate_til_candidates_if_needed(diary_type: "personal")
    return false if @diary.notes.blank?

    seed_manager = SeedManager.new(@user)

    unless seed_manager.sufficient_seeds?
      Rails.logger.debug "TIL regeneration skipped: insufficient seeds" unless Rails.env.production?
      return false
    end

    # 外部API呼び出しをトランザクション外で実行
    openai_service = AiServiceFactory.create(diary_type)
    
    begin
      til_candidates = openai_service.generate_tils(@diary.notes)

      # 外部API成功後、短時間でDB操作のみをトランザクション内で実行
      ActiveRecord::Base.transaction do
        # Clear existing candidates and generate new ones
        @diary.til_candidates.destroy_all

        til_candidates.each_with_index do |content, index|
          @diary.til_candidates.create!(content: content, index: index)
        end

        seed_manager.consume_seed!
      end

      true
    rescue StandardError => e
      # タイムアウトエラーの場合はタネを消費しない
      if AiServiceErrorHandler.timeout_error?(e)
        Rails.logger.warn "TIL regeneration timeout for user_id: #{@user.id} - seed not consumed"
        false
      else
        Rails.logger.error "TIL regeneration failed for user_id: #{@user.id}"
        Rails.logger.debug "TIL regeneration error details: #{sanitize_log_message(e.message)}" unless Rails.env.production?
        false
      end
    end
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

  private

  # バリデーション付きでanswer dataを構築（DRY原則とセキュリティ向上）
  def build_validated_answers_data(diary_answer_params)
    questions_by_identifier = Question.cached_by_identifier
    diary_answers_data = []

    diary_answer_params.each do |question_identifier, answer_id|
      question = questions_by_identifier[question_identifier.to_s]
      next unless question && answer_id.present?

      if valid_answer_for_question?(question, answer_id)
        diary_answers_data << build_answer_data(question.id, answer_id)
      else
        log_invalid_answer_attempt(question.identifier)
      end
    end

    diary_answers_data
  end

  # answer_idが該当questionの有効な値かチェック（キャッシュ汚染対策）
  def valid_answer_for_question?(question, answer_id)
    return false unless answer_id.to_s.match?(/\A\d+\z/) # 数値のみ許可

    answer_id_int = answer_id.to_i
    return false if answer_id_int <= 0 # 負数や0を拒否

    question.answers.pluck(:id).include?(answer_id_int)
  end

  def build_answer_data(question_id, answer_id)
    {
      diary_id: @diary.id,
      question_id: question_id,
      answer_id: answer_id.to_i,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def log_invalid_answer_attempt(question_identifier)
    Rails.logger.warn "Invalid answer submission for question: #{question_identifier}" unless Rails.env.production?
  end

  def sanitize_log_message(message)
    # ユーザー入力を含む可能性のある部分を除去
    message.gsub(/user input:.*$/i, "user input: [REDACTED]")
           .gsub(/notes:.*$/i, "notes: [REDACTED]")
  end
end
