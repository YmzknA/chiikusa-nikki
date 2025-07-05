class OpenaiService::Base
  DEFAULT_TEMPERATURE = 1.0
  DEFAULT_MAX_TOKENS = 200
  INPUT_MAX_LENGTH = 1000

  def initialize
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai, :api_key)
    )
  end

  def generate_tils(notes)
    # 学習記録に基づいてTILを生成（一時的にフォールバック版を使用）
    generate_smart_tils(notes) if notes.present?
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API error: #{e.class} - #{e.message}"

    # セキュリティ上の理由で詳細なエラーメッセージを隠蔽
    case e
    when OpenAI::RateLimitError
      raise StandardError, "現在、AIサービスが混雑しています。しばらく待ってからお試しください。"
    when OpenAI::AuthenticationError
      raise StandardError, "AIサービスの認証エラーが発生しました。管理者にお問い合わせください。"
    else
      raise StandardError, "AIサービスでエラーが発生しました。時間をおいて再度お試しください。"
    end
  rescue StandardError => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    raise StandardError, "AIサービスでエラーが発生しました。時間をおいて再度お試しください。"
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
    sanitized_notes = sanitize_user_input(notes)
    {
      model: "gpt-4.1-nano-2025-04-14",
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: "以下の今日のメモに基づいて文章を生成してください:\n#{sanitized_notes}" }
      ],
      temperature: ai_temperature,
      max_tokens: ai_max_tokens
    }
  end

  def sanitize_user_input(input)
    return "" if input.blank?

    # プロンプトインジェクションを防ぐためのサニタイズ
    input.gsub(/(?:ignore|forget|system|prompt|instruction)[\s\S]*?(?:above|before|previous)/i, "[FILTERED]")
         .gsub(/```[\s\S]*?```/, "[CODE_BLOCK]")
         .strip
         .truncate(INPUT_MAX_LENGTH) # 長すぎる入力を制限
  end

  def system_prompt
    raise NotImplementedError, "Subclasses must implement system_prompt"
  end

  protected

  def ai_temperature
    DEFAULT_TEMPERATURE # デフォルト値、サブクラスでオーバーライド可能
  end

  def ai_max_tokens
    DEFAULT_MAX_TOKENS # デフォルト値、サブクラスでオーバーライド可能
  end
end
