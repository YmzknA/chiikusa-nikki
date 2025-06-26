class OpenaiService
  def initialize
    ENV["OPENAI_API_KEY"] = Rails.application.credentials.dig(:openai, :api_key)
    @client = OpenAI::Client.new
  end

  def generate_tils(notes)
    # 学習記録に基づいてTILを生成（一時的にフォールバック版を使用）
    return generate_smart_tils(notes) if notes.present?

    generate_fallback_tils
  rescue StandardError => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    generate_fallback_tils
  end

  private

  def generate_smart_tils(notes)
    response = []

    3.times.map do |index|
      tils = @client.chat(
        parameters: {
          model: "gpt-4.1-nano-2025-04-14",
          messages: [
            { role: "system", content: "あなたはTIL（Today I Learned）を生成するAIです。" },
            { role: "user", content: "以下の学習記録に基づいてTILを生成してください:\n#{notes}" }
          ],
          temperature: 0.2,
          max_tokens: 150
        }
      )

      response.dig("choices", 0, "message", "content")
      tils << "TIL #{index + 1}: #{response}"
    end

    tils
  end
end
