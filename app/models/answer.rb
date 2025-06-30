class Answer < ApplicationRecord
  belongs_to :question
  has_many :diary_answers, dependent: :destroy
end
