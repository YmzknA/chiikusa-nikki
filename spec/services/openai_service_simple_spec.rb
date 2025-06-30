require "rails_helper"

RSpec.describe OpenaiService, type: :service do
  let(:service) { described_class.new }
  let(:mock_client) { instance_double(OpenAI::Client) }
  let(:notes) { "今日はRailsの勉強をした。MVCパターンを理解した。" }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
  end

  describe "#generate_tils" do
    context "when notes are present" do
      let(:mock_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "今日はRailsのMVCパターンを学んだ。\n今日はコントローラーの役割を理解した。\n今日はモデルとビューの分離を実践した。"
              }
            }
          ]
        }
      end

      before do
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end

      it "returns array of TILs" do
        result = service.generate_tils(notes)

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result.first).to include("Rails")
      end

      it "uses correct model and parameters" do
        service.generate_tils(notes)

        expect(mock_client).to have_received(:chat).exactly(3).times.with(
          parameters: hash_including(
            model: "gpt-4.1-nano-2025-04-14",
            max_tokens: 150,
            temperature: 1.3
          )
        )
      end

      it "includes system prompt with instructions" do
        service.generate_tils(notes)

        expect(mock_client).to have_received(:chat).exactly(3).times.with(
          parameters: hash_including(
            messages: array_including(
              hash_including(
                role: "system",
                content: a_string_including("プログラミング初心者または中級者", "TIL（Today I Learned）", "3文~5文")
              )
            )
          )
        )
      end

      it "includes user notes in prompt" do
        service.generate_tils(notes)

        expect(mock_client).to have_received(:chat).exactly(3).times.with(
          parameters: hash_including(
            messages: array_including(
              hash_including(
                role: "user",
                content: a_string_including(notes)
              )
            )
          )
        )
      end
    end

    context "when notes are blank" do
      it "returns nil for empty notes" do
        result = service.generate_tils("")
        expect(result).to be_nil
      end

      it "returns nil for nil notes" do
        result = service.generate_tils(nil)
        expect(result).to be_nil
      end
    end

    context "when OpenAI API fails" do
      before do
        allow(mock_client).to receive(:chat).and_raise(StandardError, "API Error")
        allow(Rails.logger).to receive(:error)
      end

      it "handles errors gracefully and logs them" do
        result = service.generate_tils(notes)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with("OpenAI API Error: API Error")
      end
    end
  end
end
