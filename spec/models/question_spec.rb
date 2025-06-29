require "rails_helper"

RSpec.describe Question, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:answers) }
  end

  describe "validations" do
    it "creates valid question with factory" do
      question = build(:question)
      expect(question).to be_valid
    end
  end

  describe "question types" do
    it "creates mood question" do
      question = create(:question, :mood)
      expect(question.identifier).to eq("mood")
      expect(question.label).to include("気分")
    end

    it "creates motivation question" do
      question = create(:question, :motivation)
      expect(question.identifier).to eq("motivation")
      expect(question.label).to include("モチベーション")
    end

    it "creates progress question" do
      question = create(:question, :progress)
      expect(question.identifier).to eq("progress")
      expect(question.label).to include("進捗")
    end
  end
end
