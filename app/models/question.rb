class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :diary_answers, dependent: :destroy

  validates :identifier, presence: true, uniqueness: true
  validates :label, presence: true
end
