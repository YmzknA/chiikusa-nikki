FactoryBot.define do
  factory :question do
    sequence(:identifier) { |n| "question_#{n}" }
    sequence(:label) { |n| "Question #{n} text" }
    icon { "❓" }

    trait :mood do
      identifier { "mood" }
      label { "今日の気分はどうでしたか？" }
      icon { "😊" }
    end

    trait :motivation do
      identifier { "motivation" }
      label { "今日のモチベーションはどうでしたか？" }
      icon { "🔥" }
    end

    trait :progress do
      identifier { "progress" }
      label { "今日の学習進捗はどうでしたか？" }
      icon { "📈" }
    end

    after(:build) do |question|
      question.answers << build(:answer, :level_1, question: question) if question.answers.empty?
    end
  end
end