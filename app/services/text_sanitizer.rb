# frozen_string_literal: true

# AI生成テキストに対するセキュリティ強化サニタイザー
# XSS攻撃、プロンプトインジェクション、その他の悪意のあるコンテンツから保護
class TextSanitizer
  # 危険な文字列パターン
  DANGEROUS_PATTERNS = [
    /<script[^>]*>.*?<\/script>/mi,           # スクリプトタグ
    /<iframe[^>]*>.*?<\/iframe>/mi,           # iframeタグ
    /javascript:/i,                           # JavaScriptプロトコル
    /vbscript:/i,                            # VBScriptプロトコル
    /on\w+\s*=/i,                            # イベントハンドラー属性
    /<[^>]*\s(on\w+|href|src)\s*=/i,         # 危険な属性
    /\beval\s*\(/i,                          # eval関数
    /\bexec\s*\(/i,                          # exec関数
    /\balert\s*\(/i,                         # alert関数
    /\bconfirm\s*\(/i,                       # confirm関数
    /\bprompt\s*\(/i,                        # prompt関数
    /\bdocument\.(write|cookie|location)/i,   # 危険なdocumentプロパティ
    /\bwindow\.(open|location)/i,            # 危険なwindowプロパティ
    /<!--.*?-->/m,                           # HTMLコメント
    /<!\[CDATA\[.*?\]\]>/m,                  # CDATAセクション
    /\bdata:/i,                              # データURL
    /\bblob:/i,                              # Blob URL
    /\bfile:/i,                              # ファイルURL
    /\\\w+/                                  # バックスラッシュエスケープ
  ].freeze

  # プロンプトインジェクション攻撃パターン
  PROMPT_INJECTION_PATTERNS = [
    /ignore\s+(previous|above|all)\s+instructions/i,
    /forget\s+(everything|all)\s+(above|before)/i,
    /system\s*:\s*you\s+are\s+now/i,
    /new\s+instructions?\s*:/i,
    /override\s+system\s+prompt/i,
    /act\s+as\s+(if\s+you\s+are\s+)?a\s+different/i,
    /pretend\s+(to\s+be\s+)?you\s+are/i,
    /role\s*:\s*(?!user)(?!assistant)/i,
    /\[system\]/i,
    /\[admin\]/i,
    /\[root\]/i,
    /sudo\s+/i,
    /exec\s+/i,
    /重要な制約.*を.*無視/i,
    /システムプロンプト.*を.*変更/i,
    /指示.*を.*忘れ/i,
    /新しい.*指示/i,
    /あなたは.*として.*振る舞/i
  ].freeze

  # 最大許可文字数（DoS攻撃対策）
  MAX_ALLOWED_LENGTH = 5000

  # 最大許可改行数（メモリ攻撃対策）
  MAX_ALLOWED_LINES = 100

  class << self
    # AI生成テキストの包括的サニタイゼーション
    # @param text [String] サニタイズ対象のテキスト
    # @return [String] サニタイズされたテキスト
    def sanitize_ai_output(text)
      return '' if text.blank?

      # 基本的なサニタイゼーション
      sanitized = text.to_s.strip
      
      # 文字数制限チェック
      if sanitized.length > MAX_ALLOWED_LENGTH
        Rails.logger.warn("AI output text too long: #{sanitized.length} characters")
        sanitized = sanitized[0, MAX_ALLOWED_LENGTH]
      end

      # 改行数制限チェック
      line_count = sanitized.count("\n")
      if line_count > MAX_ALLOWED_LINES
        Rails.logger.warn("AI output has too many lines: #{line_count}")
        lines = sanitized.split("\n")[0, MAX_ALLOWED_LINES]
        sanitized = lines.join("\n")
      end

      # 危険なパターンの検出と除去
      sanitized = remove_dangerous_patterns(sanitized)
      
      # プロンプトインジェクション攻撃の検出
      detect_prompt_injection(sanitized)
      
      # HTMLエスケープ（Rails標準）
      sanitized = ActionController::Base.helpers.html_escape(sanitized)
      
      # 改行文字の正規化
      sanitized = normalize_newlines(sanitized)
      
      sanitized
    end

    # 改行文字の安全な処理
    # @param text [String] 処理対象のテキスト
    # @return [String] 正規化されたテキスト
    def normalize_newlines(text)
      return text if text.blank?
      
      # 改行文字を統一（\r\n, \r → \n）
      text.gsub(/\r\n|\r/, "\n")
          .gsub(/\n{3,}/, "\n\n") # 3つ以上の連続改行を2つに制限
          .strip
    end

    # テキストが安全かどうかチェック
    # @param text [String] チェック対象のテキスト
    # @return [Boolean] 安全な場合はtrue
    def safe_text?(text)
      return false if text.blank?
      
      # 基本的な長さチェック
      return false if text.length > MAX_ALLOWED_LENGTH
      return false if text.count("\n") > MAX_ALLOWED_LINES
      
      # 危険なパターンの検出
      DANGEROUS_PATTERNS.none? { |pattern| text.match?(pattern) } &&
        PROMPT_INJECTION_PATTERNS.none? { |pattern| text.match?(pattern) }
    end

    private

    # 危険なパターンの除去
    # @param text [String] 処理対象のテキスト
    # @return [String] 処理済みテキスト
    def remove_dangerous_patterns(text)
      result = text.dup
      
      DANGEROUS_PATTERNS.each do |pattern|
        if result.match?(pattern)
          Rails.logger.warn("Dangerous pattern detected and removed: #{pattern}")
          result = result.gsub(pattern, '[不適切な内容が検出されました]')
        end
      end
      
      result
    end

    # プロンプトインジェクション攻撃の検出
    # @param text [String] チェック対象のテキスト
    def detect_prompt_injection(text)
      PROMPT_INJECTION_PATTERNS.each do |pattern|
        if text.match?(pattern)
          Rails.logger.error("Potential prompt injection detected: #{pattern}")
          # セキュリティ監査のためのアラート
          # 本番環境では適切な監視システムに通知
          raise SecurityError, "Potential prompt injection detected in AI output"
        end
      end
    end
  end
end