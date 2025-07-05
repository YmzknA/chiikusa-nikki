require "rails_helper"

RSpec.describe AiServiceFactory, type: :service do
  describe ".create" do
    context "when diary_type is learning" do
      it "returns LearningDiary instance" do
        service = described_class.create("learning")
        expect(service).to be_an_instance_of(OpenaiService::LearningDiary)
      end
    end

    context "when diary_type is novel" do
      it "returns NovelDiary instance" do
        service = described_class.create("novel")
        expect(service).to be_an_instance_of(OpenaiService::NovelDiary)
      end
    end

    context "when diary_type is personal" do
      it "returns PersonalDiary instance" do
        service = described_class.create("personal")
        expect(service).to be_an_instance_of(OpenaiService::PersonalDiary)
      end
    end

    context "when diary_type is nil" do
      it "returns PersonalDiary instance as default" do
        service = described_class.create(nil)
        expect(service).to be_an_instance_of(OpenaiService::PersonalDiary)
      end
    end

    context "when diary_type is unknown" do
      it "returns PersonalDiary instance as default" do
        service = described_class.create("unknown_type")
        expect(service).to be_an_instance_of(OpenaiService::PersonalDiary)
      end
    end

    context "when diary_type is symbol" do
      it "handles symbol input correctly" do
        service = described_class.create(:learning)
        expect(service).to be_an_instance_of(OpenaiService::LearningDiary)
      end
    end
  end
end
