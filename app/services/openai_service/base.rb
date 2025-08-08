class OpenaiService::Base
  DEFAULT_TEMPERATURE = 1.0
  DEFAULT_MAX_TOKENS = 200
  INPUT_MAX_LENGTH = 1000
  DEFAULT_TIMEOUT = 15
  EFFORT_LEVEL = "minimal".freeze

  def initialize
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai, :api_key),
      request_timeout: openai_timeout
    )
  end

  def generate_tils(notes)
    # 学習記録に基づいてTILを生成（一時的にフォールバック版を使用）
    generate_smart_tils(notes) if notes.present?
  rescue OpenAI::Error => e
    AiServiceErrorHandler.log_error(e, { context: "generate_tils" })
    raise StandardError, AiServiceErrorHandler.handle_openai_error(e)
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
    raw_content = response.dig("choices", 0, "message", "content")

    # 新しいTextFormatterを使用してセキュリティ強化と改行処理を実行
    TextFormatter.process_ai_text(raw_content, {
                                    sanitize: true,
                                    format_newlines: true,
                                    validate_security: true
                                  })
  end

  def til_generation_parameters(notes)
    sanitized_notes = sanitize_user_input(notes)
    {
      model: "gpt-5-nano",
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: "以下の今日のメモに基づいて文章を生成してください:\n#{sanitized_notes}" }
      ],
      temperature: ai_temperature,
      reasoning_effort: effort_level
    }
  end

  def sanitize_user_input(input)
    return "" if input.blank?

    # より厳密なプロンプトインジェクション対策
    dangerous_patterns = [
      /(?:ignore|forget|system|prompt|instruction)[\s\S]*?(?:above|before|previous)/i,
      /```[\s\S]*?```/,
      /\n\s*system[\s\S]*?:/i,
      /\n\s*assistant[\s\S]*?:/i,
      /\n\s*user[\s\S]*?:/i,
      /role\s*[:=]\s*['"](system|assistant)['"]/i
    ]

    sanitized = input.dup
    dangerous_patterns.each do |pattern|
      sanitized.gsub!(pattern, "[FILTERED]")
    end

    sanitized.strip.truncate(INPUT_MAX_LENGTH)
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

  def effort_level
    EFFORT_LEVEL # デフォルト値、サブクラスでオーバーライド可能
  end

  def openai_timeout
    ENV.fetch("OPENAI_TIMEOUT", DEFAULT_TIMEOUT).to_i
  end
end
