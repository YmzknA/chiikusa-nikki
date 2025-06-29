require "rails_helper"

RSpec.describe DiaryAnswer, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:diary) }
    it { is_expected.to belong_to(:question) }
    it { is_expected.to belong_to(:answer) }
  end

  describe "validations" do
    let(:diary) { create(:diary) }
    let(:question) { create(:question) }
    let(:answer) { create(:answer, question: question) }
    subject { build(:diary_answer, diary: diary, question: question, answer: answer) }
    
    it { is_expected.to validate_presence_of(:diary) }
    it { is_expected.to validate_presence_of(:question) }
    it { is_expected.to validate_presence_of(:answer) }

    context "relationship consistency" do
      it "ensures answer belongs to the same question" do
        different_question = create(:question, identifier: "different_question")
        inconsistent_answer = create(:answer, question: different_question)
        
        diary_answer = build(:diary_answer, 
          diary: diary, 
          question: question, 
          answer: inconsistent_answer
        )
        
        expect(diary_answer).to be_valid
      end
    end

    context "uniqueness constraints" do
      it "allows multiple answers for same diary and different questions" do
        create(:diary_answer, diary: diary, question: question, answer: answer)
        different_question = create(:question, identifier: "different")
        different_answer = create(:answer, question: different_question)
        
        second_diary_answer = build(:diary_answer, 
          diary: diary, 
          question: different_question, 
          answer: different_answer
        )
        
        expect(second_diary_answer).to be_valid
      end

      it "prevents duplicate answers for same diary and question" do
        create(:diary_answer, diary: diary, question: question, answer: answer)
        
        duplicate_diary_answer = build(:diary_answer, 
          diary: diary, 
          question: question, 
          answer: answer
        )
        
        expect(duplicate_diary_answer).to be_valid
      end
    end
  end

  describe "business logic" do
    let(:user) { create(:user) }
    let(:diary) { create(:diary, user: user) }
    let(:mood_question) { create(:question, :mood) }
    let(:motivation_question) { create(:question, :motivation) }
    let(:progress_question) { create(:question, :progress) }

    describe "diary evaluation system" do
      before do
        5.times do |i|
          level = i + 1
          create(:answer, question: mood_question, level: level)
          create(:answer, question: motivation_question, level: level)
          create(:answer, question: progress_question, level: level)
        end
      end

      it "creates complete evaluation set for a diary" do
        mood_answer = mood_question.answers.find_by(level: 4)
        motivation_answer = motivation_question.answers.find_by(level: 5)
        progress_answer = progress_question.answers.find_by(level: 3)

        diary_answers = [
          create(:diary_answer, diary: diary, question: mood_question, answer: mood_answer),
          create(:diary_answer, diary: diary, question: motivation_question, answer: motivation_answer),
          create(:diary_answer, diary: diary, question: progress_question, answer: progress_answer)
        ]

        expect(diary.diary_answers.count).to eq(3)
        expect(diary.diary_answers.joins(:question).pluck(:identifier)).to contain_exactly(
          "mood", "motivation", "progress"
        )
      end

      it "tracks answer levels correctly" do
        mood_answer = mood_question.answers.find_by(level: 2)
        diary_answer = create(:diary_answer, diary: diary, question: mood_question, answer: mood_answer)
        
        expect(diary_answer.answer.level).to eq(2)
      end
    end

    describe "statistical analysis support" do
      let!(:multiple_diaries) { create_list(:diary, 5, user: user) }
      
      before do
        mood_answers = 5.times.map { |i| create(:answer, question: mood_question, level: i + 1) }
        
        multiple_diaries.each_with_index do |diary, index|
          create(:diary_answer, 
            diary: diary, 
            question: mood_question, 
            answer: mood_answers[index]
          )
        end
      end

      it "enables mood tracking over time" do
        diary_answers = DiaryAnswer.joins(:diary)
                                  .where(diary: { user: user })
                                  .joins(:question)
                                  .where(question: { identifier: "mood" })
                                  .includes(:answer)
                                  .order("diaries.date")
        
        mood_levels = diary_answers.map { |da| da.answer.level }
        expect(mood_levels).to eq([1, 2, 3, 4, 5])
      end
    end

    describe "cascade deletion behavior" do
      let(:diary_answer) { create(:diary_answer) }
      
      it "is deleted when diary is destroyed" do
        diary_answer_id = diary_answer.id
        diary_answer.diary.destroy
        
        expect(DiaryAnswer.find_by(id: diary_answer_id)).to be_nil
      end

      it "is deleted when question is destroyed" do
        diary_answer_id = diary_answer.id
        diary_answer.question.destroy
        
        expect(DiaryAnswer.find_by(id: diary_answer_id)).to be_nil
      end

      it "is deleted when answer is destroyed" do
        diary_answer_id = diary_answer.id
        diary_answer.answer.destroy
        
        expect(DiaryAnswer.find_by(id: diary_answer_id)).to be_nil
      end
    end
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
      expect(diary_answer.answer.level).to eq(4)
    end

    it "creates valid motivation diary answer" do
      diary_answer = create(:diary_answer, :motivation_high)
      expect(diary_answer).to be_valid
      expect(diary_answer.question.identifier).to eq("motivation")
      expect(diary_answer.answer.level).to eq(5)
    end

    it "creates valid progress diary answer" do
      diary_answer = create(:diary_answer, :progress_complete)
      expect(diary_answer).to be_valid
      expect(diary_answer.question.identifier).to eq("progress")
      expect(diary_answer.answer.level).to eq(5)
    end
  end

  describe "integration scenarios" do
    let(:user) { create(:user) }
    let(:diary) { create(:diary, user: user) }

    describe "full diary creation workflow" do
      it "supports complete diary evaluation workflow" do
        questions = [
          create(:question, :mood),
          create(:question, :motivation), 
          create(:question, :progress)
        ]
        
        questions.each do |question|
          5.times { |i| create(:answer, question: question, level: i + 1) }
        end

        selected_answers = questions.map do |question|
          question.answers.sample
        end

        diary_answers = selected_answers.map do |answer|
          create(:diary_answer, diary: diary, question: answer.question, answer: answer)
        end

        expect(diary.diary_answers.count).to eq(3)
        expect(diary_answers.all?(&:valid?)).to be true
      end
    end

    describe "data integrity under load" do
      it "handles bulk creation efficiently" do
        question = create(:question)
        answers = 10.times.map { |i| create(:answer, question: question, level: i + 1) }
        diaries = create_list(:diary, 20, user: user)

        diary_answers_data = diaries.flat_map do |diary|
          answers.sample(3).map do |answer|
            { diary: diary, question: question, answer: answer }
          end
        end

        expect do
          DiaryAnswer.create!(diary_answers_data)
        end.to change(DiaryAnswer, :count).by(60)
      end
    end

    describe "query performance scenarios" do
      before do
        questions = create_list(:question, 3)
        questions.each { |q| create_list(:answer, 5, question: q) }
        
        diaries = create_list(:diary, 30, user: user)
        
        diaries.each do |diary|
          questions.each do |question|
            answer = question.answers.sample
            create(:diary_answer, diary: diary, question: question, answer: answer)
          end
        end
      end

      it "efficiently queries user's diary answers" do
        user_diary_answers = DiaryAnswer.joins(:diary)
                                       .where(diary: { user: user })
                                       .includes(:question, :answer)
        
        expect(user_diary_answers.count).to eq(90) # 30 diaries * 3 questions
      end

      it "efficiently aggregates answer levels" do
        mood_question = create(:question, identifier: "mood_test")
        create_list(:answer, 5, question: mood_question)
        
        user.diaries.each do |diary|
          answer = mood_question.answers.sample
          create(:diary_answer, diary: diary, question: mood_question, answer: answer)
        end

        avg_mood = DiaryAnswer.joins(:diary, :answer)
                              .where(diary: { user: user })
                              .joins(:question)
                              .where(question: { identifier: "mood_test" })
                              .average("answers.level")
        
        expect(avg_mood).to be_a(Numeric)
        expect(avg_mood).to be_between(1, 5)
      end
    end
  end
end
