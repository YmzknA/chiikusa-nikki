class DiaryAnswer < ApplicationRecord
  belongs_to :diary
  belongs_to :question
  belongs_to :answer
end
