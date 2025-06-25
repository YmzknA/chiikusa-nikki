require 'openai'

class OpenaiService
  def initialize
    OpenAI.configure do |config|
      config.access_token = ENV.fetch("OPENAI_API_KEY")
    end
    @client = OpenAI::Client.new
  end

  def generate_til(notes)
    prompt = <<~PROMPT
    以下の箇条書きは、プログラミング学習者の今日一日の学習記録です。
    この内容を元に、簡潔で分かりやすいTIL(Today I Learned)形式の文章を3つ作成してください。
    それぞれの文章は独立しており、ポジティブなトーンで、学習の成果が伝わるようにしてください。
    箇条書きの各項目を無理にすべて含める必要はありません。

    学習記録:
    #{notes}

    TILの例:
    - 今日は〇〇を学んだ！特に△△の部分が面白かった。
    - 〇〇でエラーが出てハマったけど、調べたら解決できた。一つ成長！
    - 〇〇のチュートリアルを完了！次は△△に挑戦したい。

    それでは、3つのTILを生成してください。
    PROMPT

    response = @client.chat(parameters: {
      model: "gpt-4-nano",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.7,
      max_tokens: 200,
      n: 3
    })

    response.dig("choices").map { |c| c.dig("message", "content") }
  end
end
