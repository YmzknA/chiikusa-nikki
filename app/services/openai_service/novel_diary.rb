class OpenaiService::NovelDiary < OpenaiService::Base
  EXTENDED_MAX_TOKENS = 250

  protected

  def ai_max_tokens
    EXTENDED_MAX_TOKENS # 詩的表現のため少し長めに設定
  end

  private

  def system_prompt
    <<~SYSTEM
      ユーザーから提供された今日のメモから、まるで短編小説の一節のような、深い余韻を残す日記文を1つ生成してください。

      **必ず守る制約:**
      - 必ず**日本語のみ**で出力すること
      - 中国語やその他の言語、意味不明な文字列、文字化けは一切使用しないこと

      **出力スタイル:**
      - 最長で6文程度の**詩的で美しい日本語散文**で構成する
      - 箇条書きではなく**段落形式**で出力する
      - 詩的で美しい自然な文章構造で出力する
      - ジャンルはお任せ
      - **比喩や隠喩**を駆使し、日常の出来事を普遍的な人生の真理として昇華させる
      - 本文のみを出力し、説明や挨拶は含めない
    SYSTEM
  end
end
