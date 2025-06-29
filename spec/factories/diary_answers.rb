FactoryBot.define do
  factory :diary_answer do
    association :diary
    association :question
    association :answer

    trait :mood_good do
      question { create(:question, :mood) }
      answer { create(:answer, :level_4, question: question) }
    end

    trait :motivation_high do
      question { create(:question, :motivation) }
      answer { create(:answer, :motivation_high, question: question) }
    end

    trait :progress_complete do
      question { create(:question, :progress) }
      answer { create(:answer, :progress_complete, question: question) }
    end
  end
end
