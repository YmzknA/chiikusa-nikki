class DiaryService
  def initialize(diary, user = nil)
    @diary = diary
    @user = user || diary.user
  end

  def create_diary_answers(diary_answer_params)
    return unless diary_answer_params.present?

    # キャッシュされたQuestionを取得
    questions_by_identifier = Question.cached_by_identifier

    # バルクインサート用の配列を準備（バリデーション付き）
    diary_answers_data = []
    diary_answer_params.each do |question_identifier, answer_id|
      question = questions_by_identifier[question_identifier.to_s]
      next unless question && answer_id.present?

      # バリデーション：answer_idが該当questionの有効なanswer_idかチェック
      valid_answer_ids = question.answers.pluck(:id)
      if valid_answer_ids.include?(answer_id.to_i)
        diary_answers_data << {
          diary_id: @diary.id,
          question_id: question.id,
          answer_id: answer_id,
          created_at: Time.current,
          updated_at: Time.current
        }
      else
        Rails.logger.warn "Invalid answer_id #{answer_id} for question #{question.identifier}"
      end
    end

    # バルクインサートで効率的に挿入
    DiaryAnswer.insert_all(diary_answers_data) if diary_answers_data.any?
  end

  def update_diary_answers(diary_answer_params)
    return unless diary_answer_params.present?

    # 効率的な削除と挿入を一回のトランザクションで実行
    ActiveRecord::Base.transaction do
      @diary.diary_answers.delete_all

      # キャッシュされたQuestionを取得
      questions_by_identifier = Question.cached_by_identifier

      # バルクインサート用の配列を準備（バリデーション付き）
      diary_answers_data = []
      diary_answer_params.each do |question_identifier, answer_id|
        question = questions_by_identifier[question_identifier.to_s]
        next unless question && answer_id.present?

        # バリデーション：answer_idが該当questionの有効なanswer_idかチェック
        valid_answer_ids = question.answers.pluck(:id)
        if valid_answer_ids.include?(answer_id.to_i)
          diary_answers_data << {
            diary_id: @diary.id,
            question_id: question.id,
            answer_id: answer_id,
            created_at: Time.current,
            updated_at: Time.current
          }
        else
          Rails.logger.warn "Invalid answer_id #{answer_id} for question #{question.identifier}"
        end
      end

      # バルクインサートで効率的に挿入
      DiaryAnswer.insert_all(diary_answers_data) if diary_answers_data.any?
    end
  end

  def handle_til_generation_and_redirect(skip_ai_generation: false)
    if @diary.notes.present? && !skip_ai_generation
      generate_til_candidates_and_redirect
    else
      { redirect_to: @diary, notice: "日記を作成しました" }
    end
  end

  def generate_til_candidates_and_redirect
    return { redirect_to: @diary, notice: "日記を作成しました（タネが不足しているためTILは生成されませんでした）" } if @user.seed_count <= 0

    # 外部API呼び出しをトランザクション外で実行
    openai_service = OpenaiService.new
    til_candidates = openai_service.generate_tils(@diary.notes)

    # 外部API成功後、短時間でDB操作のみをトランザクション内で実行
    ActiveRecord::Base.transaction do
      til_candidates.each_with_index do |content, index|
        @diary.til_candidates.create!(content: content, index: index)
      end

      @user.decrement!(:seed_count)
    end

    { redirect_to: [:select_til, @diary], notice: "日記を作成しました。続いて生成されたTIL を選択してください。" }
  rescue StandardError => e
    Rails.logger.info("Error generating TIL candidates: #{e.message}")
    { redirect_to: @diary, notice: "日記を作成しました（TIL生成でエラーが発生しました）" }
  end

  def regenerate_til_candidates_if_needed
    return false if @diary.notes.blank?

    if @user.seed_count <= 0
      Rails.logger.info("Seed count is zero, skipping TIL regeneration.")
      return false
    end

    # 外部API呼び出しをトランザクション外で実行
    openai_service = OpenaiService.new
    til_candidates = openai_service.generate_tils(@diary.notes)

    # 外部API成功後、短時間でDB操作のみをトランザクション内で実行
    ActiveRecord::Base.transaction do
      # Clear existing candidates and generate new ones
      @diary.til_candidates.destroy_all

      til_candidates.each_with_index do |content, index|
        @diary.til_candidates.create!(content: content, index: index)
      end

      @user.decrement!(:seed_count)
    end

    true
  rescue StandardError => e
    Rails.logger.error("Error regenerating TIL candidates: #{e.message}")
    false
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
