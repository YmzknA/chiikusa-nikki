require "rails_helper"

RSpec.describe DiaryService, type: :service do
  let(:user) { create(:user, :with_github, seed_count: 3) }
  let(:diary) { create(:diary, user: user) }
  let(:service) { described_class.new(diary, user) }
  let(:question) { create(:question, :mood) }
  let(:answer) { create(:answer, :level_4, question: question) }

  describe "#initialize" do
    it "sets diary and user" do
      expect(service.instance_variable_get(:@diary)).to eq(diary)
      expect(service.instance_variable_get(:@user)).to eq(user)
    end

    it "uses diary's user when user not provided" do
      service_without_user = described_class.new(diary)
      expect(service_without_user.instance_variable_get(:@user)).to eq(diary.user)
    end
  end

  describe "#create_diary_answers" do
    let(:diary_answer_params) do
      { question.identifier => answer.id }
    end

    context "with valid parameters" do
      it "creates diary answers" do
        expect do
          service.create_diary_answers(diary_answer_params)
        end.to change(DiaryAnswer, :count).by(1)

        diary_answer = DiaryAnswer.last
        expect(diary_answer.diary).to eq(diary)
        expect(diary_answer.question).to eq(question)
        expect(diary_answer.answer).to eq(answer)
      end
    end

    context "with multiple questions" do
      let(:motivation_question) { create(:question, :motivation) }
      let(:motivation_answer) { create(:answer, :motivation_high, question: motivation_question) }
      let(:multiple_params) do
        {
          question.identifier => answer.id,
          motivation_question.identifier => motivation_answer.id
        }
      end

      it "creates multiple diary answers" do
        expect do
          service.create_diary_answers(multiple_params)
        end.to change(DiaryAnswer, :count).by(2)
      end
    end

    context "with invalid parameters" do
      it "ignores invalid question identifiers" do
        invalid_params = { "invalid_question" => answer.id }

        expect do
          service.create_diary_answers(invalid_params)
        end.not_to change(DiaryAnswer, :count)
      end

      it "ignores blank answer IDs" do
        blank_params = { question.identifier => "" }

        expect do
          service.create_diary_answers(blank_params)
        end.not_to change(DiaryAnswer, :count)
      end

      it "handles nil parameters gracefully" do
        expect do
          service.create_diary_answers(nil)
        end.not_to change(DiaryAnswer, :count)
      end

      it "handles empty hash gracefully" do
        expect do
          service.create_diary_answers({})
        end.not_to change(DiaryAnswer, :count)
      end
    end
  end

  describe "#update_diary_answers" do
    let(:existing_answer) { create(:diary_answer, diary: diary, question: question, answer: answer) }
    let(:new_answer) { create(:answer, :level_2, question: question) }
    let(:update_params) { { question.identifier => new_answer.id } }

    before do
      existing_answer # Create existing answer
    end

    it "destroys existing answers and creates new ones" do
      expect do
        service.update_diary_answers(update_params)
      end.to change(DiaryAnswer, :count).by(0) # destroys 1, creates 1

      updated_answer = diary.diary_answers.last
      expect(updated_answer.answer).to eq(new_answer)
    end

    it "handles nil parameters gracefully" do
      expect do
        service.update_diary_answers(nil)
      end.to change(DiaryAnswer, :count).by(-1) # only destroys existing
    end
  end

  describe "#handle_til_generation_and_redirect" do
    let(:mock_openai_service) { instance_double(OpenaiService) }
    let(:til_contents) { ["TIL 1", "TIL 2", "TIL 3"] }

    before do
      allow(OpenaiService).to receive(:new).and_return(mock_openai_service)
      allow(mock_openai_service).to receive(:generate_tils).and_return(til_contents)
    end

    context "when notes are present and AI generation is not skipped" do
      before do
        diary.update!(notes: "Test notes for TIL generation")
      end

      context "when user has seeds" do
        it "generates TIL candidates and redirects to edit" do
          result = service.handle_til_generation_and_redirect(skip_ai_generation: false)

          expect(result[:redirect_to]).to eq([:edit, diary])
          expect(result[:notice]).to include("続いて生成されたTIL")
          expect(user.reload.seed_count).to eq(2) # decreased by 1
          expect(diary.til_candidates.count).to eq(3)
        end

        it "creates TIL candidates with correct content and indices" do
          service.handle_til_generation_and_redirect(skip_ai_generation: false)

          til_candidates = diary.til_candidates.order(:index)
          expect(til_candidates.map(&:content)).to eq(til_contents)
          expect(til_candidates.map(&:index)).to eq([0, 1, 2])
        end
      end

      context "when user has no seeds" do
        before do
          user.update!(seed_count: 0)
        end

        it "skips generation and returns appropriate notice" do
          result = service.handle_til_generation_and_redirect(skip_ai_generation: false)

          expect(result[:redirect_to]).to eq(diary)
          expect(result[:notice]).to include("タネが不足")
          expect(user.reload.seed_count).to eq(0) # unchanged
          expect(diary.til_candidates.count).to eq(0)
        end
      end
    end

    context "when notes are blank" do
      before do
        diary.update!(notes: "")
      end

      it "skips generation and redirects to diary" do
        result = service.handle_til_generation_and_redirect(skip_ai_generation: false)

        expect(result[:redirect_to]).to eq(diary)
        expect(result[:notice]).to eq("日記を作成しました")
        expect(user.reload.seed_count).to eq(3) # unchanged
      end
    end

    context "when AI generation is skipped" do
      before do
        diary.update!(notes: "Test notes")
      end

      it "skips generation regardless of notes" do
        result = service.handle_til_generation_and_redirect(skip_ai_generation: true)

        expect(result[:redirect_to]).to eq(diary)
        expect(result[:notice]).to eq("日記を作成しました")
        expect(user.reload.seed_count).to eq(3) # unchanged
      end
    end

    context "when TIL generation fails" do
      before do
        diary.update!(notes: "Test notes")
        allow(mock_openai_service).to receive(:generate_tils).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:info)
      end

      it "handles error gracefully" do
        result = service.handle_til_generation_and_redirect(skip_ai_generation: false)

        expect(result[:redirect_to]).to eq(diary)
        expect(result[:notice]).to include("TIL生成でエラーが発生")
        expect(Rails.logger).to have_received(:info).with(/Error generating TIL candidates/)
      end
    end
  end

  describe "#regenerate_til_candidates_if_needed" do
    let(:mock_openai_service) { instance_double(OpenaiService) }
    let(:new_til_contents) { ["New TIL 1", "New TIL 2", "New TIL 3"] }

    before do
      diary.update!(notes: "Updated notes")
      allow(OpenaiService).to receive(:new).and_return(mock_openai_service)
      allow(mock_openai_service).to receive(:generate_tils).and_return(new_til_contents)
    end

    context "when conditions are met" do
      before do
        create_list(:til_candidate, 3, diary: diary)
      end

      it "clears existing candidates and generates new ones" do
        expect do
          service.regenerate_til_candidates_if_needed
        end.to change { diary.til_candidates.count }.from(3).to(3)

        new_candidates = diary.til_candidates.order(:index)
        expect(new_candidates.map(&:content)).to eq(new_til_contents)
        expect(user.reload.seed_count).to eq(2) # decreased by 1
      end
    end

    context "when notes are blank" do
      before do
        diary.update!(notes: "")
      end

      it "does not regenerate" do
        expect do
          service.regenerate_til_candidates_if_needed
        end.not_to(change { diary.til_candidates.count })

        expect(user.reload.seed_count).to eq(3) # unchanged
      end
    end

    context "when user has no seeds" do
      before do
        user.update!(seed_count: 0)
        allow(Rails.logger).to receive(:info)
      end

      it "does not regenerate and logs info" do
        expect do
          service.regenerate_til_candidates_if_needed
        end.not_to(change { diary.til_candidates.count })

        expect(Rails.logger).to have_received(:info).with(/Seed count is zero/)
      end
    end

    context "when regeneration fails" do
      before do
        allow(mock_openai_service).to receive(:generate_tils).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:error)
      end

      it "handles error gracefully" do
        expect do
          service.regenerate_til_candidates_if_needed
        end.not_to raise_error

        expect(Rails.logger).to have_received(:error).with(/Error regenerating TIL candidates/)
      end
    end
  end

  describe "#handle_creation_error" do
    let(:questions) { [question] }
    let(:params) { { diary_answers: { question.identifier => answer.id } } }
    let(:current_user) { user }

    context "when date validation error occurs" do
      let(:existing_diary) { create(:diary, user: current_user, date: Date.current) }

      before do
        diary.update!(date: Date.current)
        diary.errors.add(:date, "の日記は既に作成されています")
      end

      it "returns error data with existing diary info" do
        result = service.handle_creation_error(questions, params, current_user)

        expect(result[:questions]).to eq(questions)
        expect(result[:selected_answers]).to eq({ question.identifier => answer.id })
        expect(result[:date]).to eq(Date.current)
        expect(result[:existing_diary_for_error]).to eq(existing_diary)
        expect(result[:flash_message]).to include("既に作成されています")
      end
    end

    context "when other validation errors occur" do
      before do
        diary.errors.add(:notes, "can't be blank")
      end

      it "returns error data without existing diary info" do
        result = service.handle_creation_error(questions, params, current_user)

        expect(result[:questions]).to eq(questions)
        expect(result[:selected_answers]).to eq({ question.identifier => answer.id })
        expect(result[:existing_diary_for_error]).to be_nil
        expect(result[:flash_message]).to be_nil
      end
    end

    context "with missing params" do
      let(:empty_params) { {} }

      it "handles missing diary_answers gracefully" do
        result = service.handle_creation_error(questions, empty_params, current_user)

        expect(result[:selected_answers]).to eq({})
      end
    end
  end

  describe "#handle_update_error" do
    let(:questions) { [question] }
    let(:diary_answer) { create(:diary_answer, diary: diary, question: question, answer: answer) }

    before do
      diary_answer # Create the association
    end

    it "returns error data with current answers" do
      result = service.handle_update_error(questions)

      expect(result[:questions]).to eq(questions)
      expect(result[:selected_answers]).to eq({ question.identifier => answer.id.to_s })
    end

    it "handles multiple diary answers" do
      motivation_question = create(:question, :motivation)
      motivation_answer = create(:answer, :motivation_high, question: motivation_question)
      create(:diary_answer, diary: diary, question: motivation_question, answer: motivation_answer)

      all_questions = [question, motivation_question]
      result = service.handle_update_error(all_questions)

      expected_answers = {
        question.identifier => answer.id.to_s,
        motivation_question.identifier => motivation_answer.id.to_s
      }
      expect(result[:selected_answers]).to eq(expected_answers)
    end
  end

  describe "private method behavior" do
    it "properly initializes instance variables" do
      custom_service = described_class.new(diary, user)

      expect(custom_service.instance_variable_get(:@diary)).to eq(diary)
      expect(custom_service.instance_variable_get(:@user)).to eq(user)
    end

    it "falls back to diary user when user not provided" do
      service_without_user = described_class.new(diary)

      expect(service_without_user.instance_variable_get(:@user)).to eq(diary.user)
    end
  end
end
