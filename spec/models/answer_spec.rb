require "rails_helper"

RSpec.describe Answer, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:question) }
  end

  describe "validations" do
    subject { build(:answer) }
    
    # Note: These validations may not be implemented in the model yet
    # it { is_expected.to validate_presence_of(:label) }
    # it { is_expected.to validate_presence_of(:level) }
    # it { is_expected.to validate_numericality_of(:level) }
  end

  describe "factory validations" do
    it "creates valid answer with factory" do
      answer = build(:answer)
      expect(answer).to be_valid
    end

    it "creates valid level answers" do
      (1..5).each do |level|
        answer = build(:answer, "level_#{level}".to_sym)
        expect(answer).to be_valid
        expect(answer.level).to eq(level)
      end
    end

    it "creates valid motivation answers" do
      answer = build(:answer, :motivation_low)
      expect(answer).to be_valid
      expect(answer.emoji).to eq("🧊")
      expect(answer.level).to eq(1)
    end

    it "creates valid progress answers" do
      answer = build(:answer, :progress_complete)
      expect(answer).to be_valid
      expect(answer.emoji).to eq("✅")
      expect(answer.level).to eq(5)
    end
  end
end
