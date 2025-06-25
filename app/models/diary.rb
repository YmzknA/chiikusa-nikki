class Diary < ApplicationRecord
  belongs_to :user
  has_many :diary_answers
  has_many :til_candidates
end
