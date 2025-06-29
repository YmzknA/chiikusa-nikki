FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    username { "testuser" }
    github_id { SecureRandom.uuid }
    providers { ["github"] }
    encrypted_access_token { "test_token" }
    seed_count { 3 }

    trait :with_github do
      github_id { SecureRandom.uuid }
      providers { ["github"] }
      encrypted_access_token { "github_token" }
    end

    trait :with_google do
      google_id { SecureRandom.uuid }
      google_email { email }
      providers { ["google_oauth2"] }
      encrypted_google_access_token { "google_token" }
    end

    trait :with_both_providers do
      github_id { SecureRandom.uuid }
      google_id { SecureRandom.uuid }
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