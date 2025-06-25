require 'rails_helper'

RSpec.describe DiaryAnswer, type: :model do
  describe "associations" do
    it { should belong_to(:diary) }
    it { should belong_to(:question) }
    it { should belong_to(:answer) }
  end
end
