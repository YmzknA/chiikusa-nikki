require "rails_helper"

RSpec.describe Question, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:answers) }
    it { is_expected.to have_many(:diary_answers) }
  end

  describe "validations" do
    subject { build(:question) }

    it "creates valid question with factory" do
      question = build(:question)
      expect(question).to be_valid
    end

    context "identifier validation" do
      it "requires identifier" do
        question = build(:question, identifier: nil)
        expect(question).not_to be_valid
      end

      it "requires unique identifier" do
        create(:question, identifier: "duplicate")
        question = build(:question, identifier: "duplicate")
        expect(question).not_to be_valid
      end

      it "accepts valid identifiers" do
        question = build(:question, identifier: "valid_identifier")
        expect(question).to be_valid
      end
    end

    context "label validation" do
      it "requires label" do
        question = build(:question, label: nil)
        expect(question).not_to be_valid
      end

      it "accepts various label formats" do
        question = build(:question, label: "How are you feeling today? 🙂")
        expect(question).to be_valid
      end
    end
  end

  describe "business logic" do
    let!(:mood_question) { create(:question, :mood) }
    let!(:motivation_question) { create(:question, :motivation) }
    let!(:progress_question) { create(:question, :progress) }

    describe "question system" do
      it "creates all standard question types" do
        expect(Question.count).to be >= 3
        expect(Question.find_by(identifier: "mood")).to be_present
        expect(Question.find_by(identifier: "motivation")).to be_present
        expect(Question.find_by(identifier: "progress")).to be_present
      end

      it "maintains unique identifiers" do
        identifiers = Question.pluck(:identifier)
        expect(identifiers.uniq.size).to eq(identifiers.size)
      end
    end

    describe "answers relationship" do
      before do
        5.times do |i|
          create(:answer, question: mood_question, level: i + 1)
        end
      end

      it "has associated answers" do
        expect(mood_question.answers.count).to eq(5)
      end

      it "maintains proper level ordering" do
        levels = mood_question.answers.order(:level).pluck(:level)
        expect(levels).to eq([1, 2, 3, 4, 5])
      end
    end

    describe "diary answers relationship" do
      let(:diary) { create(:diary) }
      let!(:diary_answer) { create(:diary_answer, diary: diary, question: mood_question) }

      it "tracks diary responses" do
        expect(mood_question.diary_answers).to include(diary_answer)
      end
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

  describe "edge cases and data integrity" do
    describe "cascade deletion" do
      let(:question) { create(:question) }
      let!(:answers) { create_list(:answer, 3, question: question) }
      let!(:diary_answers) { create_list(:diary_answer, 2, question: question) }

      it "handles associated records on deletion" do
        answer_ids = question.answers.pluck(:id)
        diary_answer_ids = question.diary_answers.pluck(:id)

        question.destroy

        answer_ids.each do |id|
          expect(Answer.find_by(id: id)).to be_nil
        end

        diary_answer_ids.each do |id|
          expect(DiaryAnswer.find_by(id: id)).to be_nil
        end
      end
    end

    describe "encoding and special characters" do
      it "handles Japanese text properly" do
        question = create(:question,
                          identifier: "japanese_test",
                          label: "今日の気分はいかがですか？ 😊")
        expect(question.reload.label).to include("😊")
      end
    end

    describe "performance with large datasets" do
      it "performs efficiently with many answers" do
        question = create(:question)

        expect do
          100.times { |i| create(:answer, question: question, level: (i % 5) + 1) }
        end.to change(question.answers, :count).by(100)

        expect(question.answers.count).to eq(100)
      end
    end
  end
end
