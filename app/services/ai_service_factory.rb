class AiServiceFactory
  VALID_DIARY_TYPES = %w[personal learning novel].freeze

  class << self
    def create(diary_type)
      normalized_type = diary_type.to_s.strip
      normalized_type = "personal" if normalized_type.blank?

      unless VALID_DIARY_TYPES.include?(normalized_type)
        raise ArgumentError, "Invalid diary type: #{normalized_type}. Valid types are: #{VALID_DIARY_TYPES.join(', ')}"
      end

      case normalized_type
      when "learning"
        OpenaiService::LearningDiary.new
      when "novel"
        OpenaiService::NovelDiary.new
      else
        OpenaiService::PersonalDiary.new
      end
    end
  end
end
