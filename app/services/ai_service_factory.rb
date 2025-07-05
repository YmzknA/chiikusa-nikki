class AiServiceFactory
  class << self
    def create(diary_type)
      case diary_type.to_s
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
