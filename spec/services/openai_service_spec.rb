require "rails_helper"

RSpec.describe OpenaiService, type: :service do
  let(:service) { described_class.new }
  let(:mock_client) { instance_double(OpenAI::Client) }
  let(:notes) { "- Learned about RSpec testing\n- Practiced factory_bot usage\n- Understood shoulda matchers" }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
  end

  describe "#initialize" do
    it "creates OpenAI client with API key from credentials" do
      expect(OpenAI::Client).to receive(:new).with(
        access_token: Rails.application.credentials.dig(:openai, :api_key)
      )
      
      described_class.new
    end
  end

  describe "#generate_tils" do
    let(:mock_response) do
      {
        "choices" => [
          {
            "message" => {
              "content" => "今日はRSpecを使用したテスト駆動開発について学んだ。テストファーストのアプローチで、より堅牢なコードを書けるようになった。"
            }
          }
        ]
      }
    end

    context "when notes are present" do
      before do
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end

      it "generates 3 TIL candidates" do
        result = service.generate_tils(notes)
        
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(mock_client).to have_received(:chat).exactly(3).times
      end

      it "uses correct model and parameters" do
        service.generate_tils(notes)
        
        expect(mock_client).to have_received(:chat).with(
          parameters: hash_including(
            model: "gpt-4.1-nano-2025-04-14",
            temperature: 1.5,
            max_tokens: 150,
            messages: array_including(
              hash_including(role: "system"),
              hash_including(role: "user", content: include(notes))
            )
          )
        )
      end

      it "includes system prompt with instructions" do
        service.generate_tils(notes)
        
        system_message = mock_client.received_messages.first.dig(:parameters, :messages, 0)
        expect(system_message[:role]).to eq("system")
        expect(system_message[:content]).to include("プログラミング初心者または中級者")
        expect(system_message[:content]).to include("TIL（Today I Learned）")
        expect(system_message[:content]).to include("3文~5文")
      end

      it "includes user notes in prompt" do
        service.generate_tils(notes)
        
        user_message = mock_client.received_messages.first.dig(:parameters, :messages, 1)
        expect(user_message[:role]).to eq("user")
        expect(user_message[:content]).to include(notes)
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

    context "when OpenAI API returns partial responses" do
      let(:partial_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "Valid TIL content"
              }
            }
          ]
        }
      end

      let(:empty_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => ""
              }
            }
          ]
        }
      end

      let(:nil_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => nil
              }
            }
          ]
        }
      end

      before do
        allow(mock_client).to receive(:chat)
          .and_return(partial_response, empty_response, nil_response)
      end

      it "filters out empty or nil responses" do
        result = service.generate_tils(notes)
        
        expect(result).to eq(["Valid TIL content"])
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
        expect(Rails.logger).to have_received(:error).with(kind_of(String)) # backtrace
      end
    end

    context "when OpenAI returns malformed response" do
      let(:malformed_response) do
        {
          "choices" => []
        }
      end

      before do
        allow(mock_client).to receive(:chat).and_return(malformed_response)
      end

      it "handles malformed responses gracefully" do
        result = service.generate_tils(notes)
        
        expect(result).to eq([])
      end
    end
  end

  describe "private method #generate_smart_tils" do
    let(:mock_responses) do
      [
        {
          "choices" => [
            {
              "message" => {
                "content" => "今日はRSpecについて学んだ。テストの書き方が理解できた。"
              }
            }
          ]
        },
        {
          "choices" => [
            {
              "message" => {
                "content" => "FactoryBotを使ったテストデータ生成を学んだ。効率的にテストが書けるようになった。"
              }
            }
          ]
        },
        {
          "choices" => [
            {
              "message" => {
                "content" => "ShouldaMatchersでバリデーションテストを簡潔に書く方法を学んだ。"
              }
            }
          ]
        }
      ]
    end

    before do
      allow(mock_client).to receive(:chat).and_return(*mock_responses)
    end

    it "generates exactly 3 TIL candidates" do
      result = service.send(:generate_smart_tils, notes)
      
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result).to all(be_a(String))
    end

    it "uses high temperature for creative responses" do
      service.send(:generate_smart_tils, notes)
      
      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(temperature: 1.5)
      ).exactly(3).times
    end

    it "limits response length appropriately" do
      service.send(:generate_smart_tils, notes)
      
      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(max_tokens: 150)
      ).exactly(3).times
    end
  end

  describe "system prompt validation" do
    before do
      allow(mock_client).to receive(:chat).and_return({
        "choices" => [{ "message" => { "content" => "Test TIL" } }]
      })
    end

    it "includes all required instructions in system prompt" do
      service.generate_tils(notes)
      
      system_content = mock_client.received_messages.first.dig(:parameters, :messages, 0, :content)
      
      expect(system_content).to include("3文~5文")
      expect(system_content).to include("箇条書きではなく自然な文章")
      expect(system_content).to include("今日は〜を学んだ")
      expect(system_content).to include("TIL文のみで、前後に説明や挨拶は不要")
    end

    it "provides clear output format instructions" do
      service.generate_tils(notes)
      
      system_content = mock_client.received_messages.first.dig(:parameters, :messages, 0, :content)
      
      expect(system_content).to include("学んだことや、今日やったことを具体的に")
      expect(system_content).to include("〜ができるようになった")
      expect(system_content).to include("〜を理解した")
      expect(system_content).to include("～をした")
    end
  end

  describe "error handling scenarios" do
    let(:error_scenarios) do
      [
        [OpenAI::Error, "OpenAI API Error"],
        [StandardError, "General Error"],
        [Net::TimeoutError, "Timeout Error"],
        [JSON::ParserError, "JSON Parse Error"]
      ]
    end

    before do
      allow(Rails.logger).to receive(:error)
    end

    it "handles various error types gracefully" do
      error_scenarios.each do |error_class, error_message|
        allow(mock_client).to receive(:chat).and_raise(error_class, error_message)
        
        result = service.generate_tils(notes)
        
        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with("OpenAI API Error: #{error_message}")
      end
    end
  end

  describe "integration with Rails credentials" do
    context "when API key is missing" do
      before do
        allow(Rails.application.credentials).to receive(:dig).with(:openai, :api_key).and_return(nil)
      end

      it "handles missing credentials gracefully" do
        expect { described_class.new }.not_to raise_error
      end
    end

    context "when API key is present" do
      before do
        allow(Rails.application.credentials).to receive(:dig).with(:openai, :api_key).and_return("test-api-key")
      end

      it "uses the configured API key" do
        expect(OpenAI::Client).to receive(:new).with(access_token: "test-api-key")
        described_class.new
      end
    end
  end
end