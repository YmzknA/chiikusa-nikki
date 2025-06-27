class DiaryService
  def initialize(diary, user = nil)
    @diary = diary
    @user = user || diary.user
  end

  def create_diary_answers(params)
    return unless params[:answers].present?

    Question.find_each do |question|
      answer_id = params[:answers][question.identifier]
      next unless answer_id.present?

      answer = question.answers.find(answer_id)
      @diary.diary_answers.create!(
        question: question,
        answer: answer
      )
    end
  end

  def update_diary_answers(params)
    return unless params[:answers].present?

    @diary.diary_answers.destroy_all

    Question.find_each do |question|
      answer_id = params[:answers][question.identifier]
      next unless answer_id.present?

      answer = question.answers.find(answer_id)
      @diary.diary_answers.create!(
        question: question,
        answer: answer
      )
    end
  end

  def regenerate_til_candidates_if_needed(notes_changed, til_text_changed)
    return unless notes_changed || til_text_changed
    return if @diary.notes.blank?

    generate_til_candidates
  end

  def generate_til_candidates_async
    GenerateTilJob.perform_later(@diary.id)
  end

  private

  def generate_til_candidates
    GenerateTilJob.perform_now(@diary.id)
  end
end
