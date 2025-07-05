class OpenaiService::Base
  def initialize
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai, :api_key)
    )
  end

  def generate_tils(notes)
    # 学習記録に基づいてTILを生成（一時的にフォールバック版を使用）
    generate_smart_tils(notes) if notes.present?
  rescue StandardError => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
  end

  private

  def generate_smart_tils(notes)
    tils = []
    3.times { tils << generate_single_til(notes) }
    tils.compact
  end

  def generate_single_til(notes)
    response = @client.chat(parameters: til_generation_parameters(notes))
    response.dig("choices", 0, "message", "content")
  end

  def til_generation_parameters(notes)
    {
      model: "gpt-4.1-nano-2025-04-14",
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: "以下の今日のメモに基づいて文章を生成してください:\n#{notes}" }
      ],
      temperature: 1,
      max_tokens: 200
    }
  end

  def system_prompt
    raise NotImplementedError, "Subclasses must implement system_prompt"
  end
end