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
                あなたは、プログラミング初心者または中級者が書いた学習メモから、シンプルで実用的なTIL（Today I Learned）文を1つ生成するAIです。
                出力は以下の条件に従ってください:

                - フォーマットは1文~3文、箇条書きではなく自然な文章にしてください。
                - 学んだことを具体的に伝えるようにしてください（例：〜ができるようになった、〜を理解した）。
                - 主語「今日は〜を学んだ」「〜を理解できた」などを使ってください。
                - 出力はTIL文のみで、前後に説明や挨拶は不要です。
                - 入力は箇条書きで、それぞれ別の項目で、それぞれについて個別にTILを生成してください。
              SYSTEM
            },
            { role: "user", content: "以下の学習記録に基づいてTILを生成してください:\n#{notes}" }
          ],
          temperature: 1.5,
          max_tokens: 150
        }
      )

      content = response.dig("choices", 0, "message", "content")
      tils << content if content.present?
    end

    tils
  end
end
