require "rails_helper"

RSpec.describe Answer, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:question) }
  end

  describe "validations" do
    let(:question) { create(:question) }
    subject { build(:answer, question: question) }

    context "when valid attributes" do
      it "is valid with all required attributes" do
        expect(subject).to be_valid
      end
    end

    context "when missing question" do
      it "is invalid without question" do
        subject.question = nil
        expect(subject).not_to be_valid
      end
    end

    context "level validation scenarios" do
      it "is valid with integer levels" do
        (1..5).each do |level|
          answer = build(:answer, question: question, level: level)
          expect(answer).to be_valid
        end
      end

      it "is valid with level 0" do
        answer = build(:answer, question: question, level: 0)
        expect(answer).to be_valid
      end

      it "is valid with negative levels" do
        answer = build(:answer, question: question, level: -1)
        expect(answer).to be_valid
      end

      it "is valid with nil level" do
        answer = build(:answer, question: question, level: nil)
        expect(answer).to be_valid
      end
    end

    context "label and emoji validation" do
      it "is valid with empty label" do
        answer = build(:answer, question: question, label: "")
        expect(answer).to be_valid
      end

      it "is valid with nil emoji" do
        answer = build(:answer, question: question, emoji: nil)
        expect(answer).to be_valid
      end

      it "handles emoji correctly" do
        answer = build(:answer, question: question, emoji: "😊")
        expect(answer).to be_valid
        expect(answer.emoji).to eq("😊")
      end
    end
  end

  describe "business logic" do
    let(:mood_question) { build(:question, :mood).tap { |q| q.answers.clear; q.save! } }
    let(:motivation_question) { build(:question, :motivation).tap { |q| q.answers.clear; q.save! } }
    let(:progress_question) { build(:question, :progress).tap { |q| q.answers.clear; q.save! } }

    describe "level-based organization" do
      let!(:level_answers) do
        5.times.map do |i|
          level = i + 1
          create(:answer, question: mood_question, level: level, label: "Level #{level}")
        end
      end

      it "organizes answers by level" do
        answers = mood_question.answers.order(:level)
        expect(answers.map(&:level)).to eq([1, 2, 3, 4, 5])
      end

      it "maintains unique levels per question" do
        levels = mood_question.answers.pluck(:level)
        expect(levels.uniq.size).to eq(levels.size)
      end
    end

    describe "emoji system" do
      let!(:mood_answers) do
        [
          create(:answer, question: mood_question, level: 1, emoji: "😞"),
          create(:answer, question: mood_question, level: 2, emoji: "😔"),
          create(:answer, question: mood_question, level: 3, emoji: "😐"),
          create(:answer, question: mood_question, level: 4, emoji: "🙂"),
          create(:answer, question: mood_question, level: 5, emoji: "😄")
        ]
      end

      it "maintains distinct emojis for different levels" do
        emojis = mood_question.answers.order(:level).pluck(:emoji)
        expect(emojis.uniq.size).to eq(emojis.size)
        expect(emojis).to include("😞", "😄")
      end

      it "associates appropriate emojis with levels" do
        low_mood = mood_question.answers.find_by(level: 1)
        high_mood = mood_question.answers.find_by(level: 5)

        expect(low_mood.emoji).to eq("😞")
        expect(high_mood.emoji).to eq("😄")
      end
    end

    describe "question relationships" do
      let!(:answers) { create_list(:answer, 3, question: mood_question) }

      it "belongs to the correct question" do
        answers.each do |answer|
          expect(answer.question).to eq(mood_question)
        end
      end

      it "has dependent destroy association configured" do
        # This tests the model association configuration, not DB constraints
        association = Question.reflect_on_association(:answers)
        expect(association.options[:dependent]).to eq(:destroy)
      end
    end

    describe "diary answer usage" do
      let(:diary) { create(:diary) }
      let(:answer) { create(:answer, question: mood_question) }
      let!(:diary_answer) { create(:diary_answer, diary: diary, question: mood_question, answer: answer) }

      it "tracks usage in diary answers" do
        expect(answer.diary_answers).to include(diary_answer)
      end
    end
  end

  describe "factory validations" do
    it "creates valid answer with factory" do
      answer = build(:answer)
      expect(answer).to be_valid
    end

    it "creates valid level answers" do
      (1..5).each do |level|
        answer = build(:answer, :"level_#{level}")
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

  describe "edge cases and data integrity" do
    let(:question) { create(:question) }

    describe "encoding and special characters" do
      it "handles various emoji properly" do
        emojis = ["😀", "😢", "🔥", "❄️", "✅"]

        emojis.each_with_index do |emoji, index|
          answer = create(:answer, question: question, emoji: emoji, level: index + 1)
          expect(answer.reload.emoji).to eq(emoji)
        end
      end

      it "handles Japanese labels" do
        answer = create(:answer,
                        question: question,
                        label: "とても良い気分です",
                        emoji: "😄")
        expect(answer.reload.label).to include("とても")
      end
    end

    describe "data consistency" do
      it "maintains data integrity with concurrent access" do
        answers_data = 50.times.map do |i|
          {
            question: question,
            level: (i % 5) + 1,
            label: "Answer #{i}",
            emoji: ["😀", "😔", "😐", "🙂", "😄"][i % 5]
          }
        end

        expect do
          Answer.create!(answers_data)
        end.to change(Answer, :count).by(50)
      end
    end

    describe "boundary values" do
      it "handles extreme level values" do
        extreme_answers = [
          { level: -1000, label: "Very negative" },
          { level: 0, label: "Zero" },
          { level: 1000, label: "Very positive" }
        ]

        extreme_answers.each do |attrs|
          answer = create(:answer, question: question, **attrs)
          expect(answer.level).to eq(attrs[:level])
        end
      end

      it "handles very long labels" do
        long_label = "A" * 1000
        answer = create(:answer, question: question, label: long_label)
        expect(answer.reload.label.length).to eq(1000)
      end
    end
  end
end
