class OpenaiService
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
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def generate_smart_tils(notes)
    tils = []

    3.times do
      response = @client.chat(
        parameters: {
          model: "gpt-4.1-nano-2025-04-14",
          messages: [
            {
              role: "system",
              content: <<~SYSTEM
                あなたは、ユーザーが書いた今日のメモから、シンプルで実用的なTIL（Today I Learned）文を1つ生成するAIです。

                **重要な制約:**
                - 必ず日本語のみで出力してください
                - 中国語、その他の言語は一切使用しないでください
                - 文字化けや記号の羅列は避けてください
                - 意味不明な文字列や暗号化されたような文字列は生成しないでください

                **出力フォーマット:**
                - 3文~5文の自然な日本語文章
                - 箇条書きではなく段落形式
                - 「今日は〜を学んだ」「〜を理解できた」「～をやった」などの主語を使用
                - メモの内容を具体的に表現
                - TIL文のみを出力（説明や挨拶は不要）
              SYSTEM
            },
            { role: "user", content: "以下の今日のメモに基づいて文章を生成してください:\n#{notes}" }
          ],
          temperature: 1, # 温度を下げて安定性向上
          max_tokens: 300 # トークン数を増加
        }
      )

      content = response.dig("choices", 0, "message", "content")
      tils << content if content.present?
    end

    tils
  end
end
