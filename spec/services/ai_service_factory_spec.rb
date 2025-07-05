require "rails_helper"

RSpec.describe AiServiceFactory, type: :service do
  describe ".create" do
    context "with valid diary types" do
      it "returns PersonalDiary for 'personal'" do
        service = AiServiceFactory.create("personal")
        expect(service).to be_a(OpenaiService::PersonalDiary)
      end

      it "returns LearningDiary for 'learning'" do
        service = AiServiceFactory.create("learning")
        expect(service).to be_a(OpenaiService::LearningDiary)
      end

      it "returns NovelDiary for 'novel'" do
        service = AiServiceFactory.create("novel")
        expect(service).to be_a(OpenaiService::NovelDiary)
      end

      it "returns PersonalDiary for nil (default)" do
        service = AiServiceFactory.create(nil)
        expect(service).to be_a(OpenaiService::PersonalDiary)
      end

      it "returns PersonalDiary for empty string (default)" do
        service = AiServiceFactory.create("")
        expect(service).to be_a(OpenaiService::PersonalDiary)
      end
    end

    context "with invalid diary types" do
      it "raises ArgumentError for invalid type" do
        expect { AiServiceFactory.create("invalid_type") }.to raise_error(
          ArgumentError,
          "Invalid diary type: invalid_type. Valid types are: personal, learning, novel"
        )
      end

      it "raises ArgumentError for numeric type" do
        expect { AiServiceFactory.create(123) }.to raise_error(
          ArgumentError,
          "Invalid diary type: 123. Valid types are: personal, learning, novel"
        )
      end

      it "raises ArgumentError for special characters" do
        expect { AiServiceFactory.create("personal; DROP TABLE users;") }.to raise_error(
          ArgumentError
        )
      end
    end

    context "with edge cases" do
      it "handles string with whitespace by trimming" do
        service = AiServiceFactory.create(" personal ")
        expect(service).to be_a(OpenaiService::PersonalDiary)
      end

      it "handles case sensitivity" do
        expect { AiServiceFactory.create("Personal") }.to raise_error(ArgumentError)
        expect { AiServiceFactory.create("LEARNING") }.to raise_error(ArgumentError)
      end
    end
  end

  describe "VALID_DIARY_TYPES" do
    it "is frozen to prevent modification" do
      expect(AiServiceFactory::VALID_DIARY_TYPES).to be_frozen
    end

    it "contains expected types" do
      expected_types = %w[personal learning novel]
      expect(AiServiceFactory::VALID_DIARY_TYPES).to eq(expected_types)
    end
  end
end
