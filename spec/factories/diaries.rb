FactoryBot.define do
  factory :diary do
    association :user
    sequence(:date) { |n| Date.current - n.days }
    notes { "Today I learned about testing and Rails development." }
    is_public { false }
    github_uploaded { false }
    selected_til_index { nil }

    trait :with_notes do
      notes { "Detailed learning notes about programming concepts and implementation." }
    end

    trait :public do
      is_public { true }
    end

    trait :github_uploaded do
      github_uploaded { true }
      github_uploaded_at { Time.current }
      github_file_path { "#{date.strftime('%y%m%d')}_til.md" }
      github_repository_url { "https://github.com/testuser/test-til" }
      github_commit_sha { "abc123def456" }
    end

    trait :with_til_candidates do
      after(:create) do |diary|
        create(:til_candidate, :first, diary: diary)
        create(:til_candidate, :second, diary: diary)
        create(:til_candidate, :third, diary: diary)
      end
    end

    trait :with_selected_til do
      selected_til_index { 0 }
      with_til_candidates
    end

    trait :with_answers do
      after(:create) do |diary|
        questions = Question.all
        questions.each do |question|
          answer = question.answers.sample
          create(:diary_answer, diary: diary, question: question, answer: answer)
        end
      end
    end
  end
end
