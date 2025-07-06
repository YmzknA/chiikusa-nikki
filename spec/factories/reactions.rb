FactoryBot.define do
  factory :reaction do
    association :user
    association :diary
    emoji { Reaction::ALL_EMOJIS.sample }
  end
end
