FactoryBot.define do
  factory :answer do
    association :question
    sequence(:label) { |n| "Answer #{n}" }
    sequence(:level) { |n| n }
    emoji { "⭐" }

    trait :level_one do
      label { "Very Low" }
      emoji { "😞" }
      level { 1 }
    end

    trait :level_two do
      label { "Low" }
      emoji { "😔" }
      level { 2 }
    end

    trait :level_three do
      label { "Medium" }
      emoji { "😐" }
      level { 3 }
    end

    trait :level_four do
      label { "High" }
      emoji { "🙂" }
      level { 4 }
    end

    trait :level_five do
      label { "Very High" }
      emoji { "😄" }
      level { 5 }
    end

    # Motivation specific answers
    trait :motivation_low do
      label { "Cold" }
      emoji { "🧊" }
      level { 1 }
    end

    trait :motivation_high do
      label { "Hot" }
      emoji { "🔥" }
      level { 5 }
    end

    # Progress specific answers
    trait :progress_none do
      label { "No Progress" }
      emoji { "✖️" }
      level { 1 }
    end

    trait :progress_complete do
      label { "Complete" }
      emoji { "✅" }
      level { 5 }
    end
  end
end
