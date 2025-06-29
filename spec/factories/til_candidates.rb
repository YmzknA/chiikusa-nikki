FactoryBot.define do
  factory :til_candidate do
    association :diary
    sequence(:content) { |n| "Today I learned about important concept ##{n} in software development." }
    sequence(:index) { |n| n }

    trait :first do
      index { 0 }
      content { "Today I learned about test-driven development and its benefits." }
    end

    trait :second do
      index { 1 }
      content { "Today I learned about refactoring patterns and clean code principles." }
    end

    trait :third do
      index { 2 }
      content { "Today I learned about database optimization and query performance." }
    end
  end
end
