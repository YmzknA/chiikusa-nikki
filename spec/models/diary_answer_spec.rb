require "rails_helper"

RSpec.describe DiaryAnswer, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:diary) }
    it { is_expected.to belong_to(:question) }
    it { is_expected.to belong_to(:answer) }
  end

  describe "validations" do
    subject { build(:diary_answer) }
    
    it { is_expected.to validate_presence_of(:diary) }
    it { is_expected.to validate_presence_of(:question) }
    it { is_expected.to validate_presence_of(:answer) }
  end

  describe "factory validations" do
    it "creates valid diary_answer with factory" do
      diary_answer = build(:diary_answer)
      expect(diary_answer).to be_valid
    end

    it "creates valid mood diary answer" do
      diary_answer = create(:diary_answer, :mood_good)
      expect(diary_answer).to be_valid
      expect(diary_answer.question.identifier).to eq("mood")
      expect(diary_answer.answer.value).to eq(4)
    end

    it "creates valid motivation diary answer" do
      diary_answer = create(:diary_answer, :motivation_high)
      expect(diary_answer).to be_valid
      expect(diary_answer.question.identifier).to eq("motivation")
      expect(diary_answer.answer.value).to eq(5)
    end

    it "creates valid progress diary answer" do
      diary_answer = create(:diary_answer, :progress_complete)
      expect(diary_answer).to be_valid
      expect(diary_answer.question.identifier).to eq("progress")
      expect(diary_answer.answer.value).to eq(5)
    end
  end
end
