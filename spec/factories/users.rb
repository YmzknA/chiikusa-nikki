FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "testuser#{n}" }
    seed_count { 3 }
    
    # デフォルトではGitHub認証ユーザーとして作成
    sequence(:github_id) { |n| "github_#{n}_#{SecureRandom.hex(4)}" }
    providers { ["github"] }
    encrypted_access_token { "test_token" }

    trait :with_github do
      sequence(:github_id) { |n| "github_#{n}_#{SecureRandom.hex(4)}" }
      providers { ["github"] }
      encrypted_access_token { "github_token" }
    end

    trait :with_google do
      github_id { nil }
      encrypted_access_token { nil }
      sequence(:google_id) { |n| "google_#{n}_#{SecureRandom.hex(4)}" }
      google_email { email }
      providers { ["google_oauth2"] }
      encrypted_google_access_token { "google_token" }
    end

    trait :with_both_providers do
      sequence(:github_id) { |n| "github_#{n}_#{SecureRandom.hex(4)}" }
      sequence(:google_id) { |n| "google_#{n}_#{SecureRandom.hex(4)}" }
      google_email { email }
      providers { ["github", "google_oauth2"] }
      encrypted_access_token { "github_token" }
      encrypted_google_access_token { "google_token" }
    end

    trait :username_setup_pending do
      username { User::DEFAULT_USERNAME }
    end

    trait :with_github_repo do
      github_repo_name { "test-til-repo" }
    end
  end
end