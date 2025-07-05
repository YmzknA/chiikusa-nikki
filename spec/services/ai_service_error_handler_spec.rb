require "rails_helper"

RSpec.describe AiServiceErrorHandler, type: :service do
  describe ".handle_openai_error" do
    context "with rate limit error" do
      it "returns rate limit message" do
        error = double("RateLimitError", class: double(name: "OpenAI::RateLimitError"))
        result = AiServiceErrorHandler.handle_openai_error(error)
        expect(result).to eq("現在、AIサービスが混雑しています。しばらく待ってからお試しください。")
      end
    end

    context "with authentication error" do
      it "returns authentication error message" do
        error = double("AuthError", class: double(name: "OpenAI::AuthenticationError"))
        result = AiServiceErrorHandler.handle_openai_error(error)
        expect(result).to eq("AIサービスの認証エラーが発生しました。管理者にお問い合わせください。")
      end
    end

    context "with timeout errors" do
      it "returns timeout message for Net::TimeoutError" do
        error = double("TimeoutError", class: double(name: "Net::TimeoutError"))
        result = AiServiceErrorHandler.handle_openai_error(error)
        expect(result).to eq("AIサービスの応答に時間がかかりすぎています。時間をおいて再度お試しください。")
      end

      it "returns timeout message for Timeout::Error" do
        error = double("TimeoutError", class: double(name: "Timeout::Error"))
        result = AiServiceErrorHandler.handle_openai_error(error)
        expect(result).to eq("AIサービスの応答に時間がかかりすぎています。時間をおいて再度お試しください。")
      end

      it "returns timeout message for Net::ReadTimeout" do
        error = double("ReadTimeoutError", class: double(name: "Net::ReadTimeout"))
        result = AiServiceErrorHandler.handle_openai_error(error)
        expect(result).to eq("AIサービスの応答に時間がかかりすぎています。時間をおいて再度お試しください。")
      end
    end

    context "with other errors" do
      it "returns general error message" do
        error = double("StandardError", class: double(name: "StandardError"))
        result = AiServiceErrorHandler.handle_openai_error(error)
        expect(result).to eq("AIサービスでエラーが発生しました。時間をおいて再度お試しください。")
      end
    end
  end

  describe ".timeout_error?" do
    it "returns true for Net::TimeoutError" do
      error = double("TimeoutError", class: double(name: "Net::TimeoutError"))
      expect(AiServiceErrorHandler.timeout_error?(error)).to be true
    end

    it "returns true for Timeout::Error" do
      error = double("TimeoutError", class: double(name: "Timeout::Error"))
      expect(AiServiceErrorHandler.timeout_error?(error)).to be true
    end

    it "returns true for Net::ReadTimeout" do
      error = double("ReadTimeoutError", class: double(name: "Net::ReadTimeout"))
      expect(AiServiceErrorHandler.timeout_error?(error)).to be true
    end

    it "returns false for other errors" do
      error = double("StandardError", class: double(name: "StandardError"))
      expect(AiServiceErrorHandler.timeout_error?(error)).to be false
    end
  end

  describe ".log_error" do
    let(:error) { StandardError.new("Test error") }

    before do
      allow(Rails.logger).to receive(:error)
      allow(Rails.logger).to receive(:debug)
    end

    it "logs error with class and message" do
      AiServiceErrorHandler.log_error(error)
      expect(Rails.logger).to have_received(:error).with("OpenAI API error: StandardError - Test error")
    end

    context "with context" do
      it "logs context in debug mode when not in production" do
        allow(Rails.env).to receive(:production?).and_return(false)
        
        AiServiceErrorHandler.log_error(error, { user_id: 123, action: "generate_tils" })
        
        expect(Rails.logger).to have_received(:debug).with("Error context: {:user_id=>123, :action=>\"generate_tils\"}")
      end

      it "does not log context in production" do
        allow(Rails.env).to receive(:production?).and_return(true)
        
        AiServiceErrorHandler.log_error(error, { user_id: 123 })
        
        expect(Rails.logger).not_to have_received(:debug)
      end
    end
  end

  describe "MESSAGES constant" do
    it "is frozen to prevent modification" do
      expect(AiServiceErrorHandler::MESSAGES).to be_frozen
    end

    it "contains expected message keys" do
      expected_keys = [:rate_limit, :auth_error, :timeout, :general]
      expect(AiServiceErrorHandler::MESSAGES.keys).to match_array(expected_keys)
    end

    it "contains Japanese error messages" do
      expect(AiServiceErrorHandler::MESSAGES[:rate_limit]).to include("混雑")
      expect(AiServiceErrorHandler::MESSAGES[:auth_error]).to include("認証エラー")
      expect(AiServiceErrorHandler::MESSAGES[:timeout]).to include("時間がかかりすぎて")
      expect(AiServiceErrorHandler::MESSAGES[:general]).to include("エラーが発生")
    end
  end
end