# frozen_string_literal: true

# AI生成テキストの統一的なフォーマッティング処理
# 改行処理、サニタイゼーション、セキュリティ検証を統合
class TextFormatter
  class << self
    # AI生成テキストの包括的処理
    # @param text [String] 処理対象のテキスト
    # @param options [Hash] 処理オプション
    # @option options [Boolean] :sanitize セキュリティサニタイゼーションを実行（デフォルト: true）
    # @option options [Boolean] :format_newlines 改行フォーマットを実行（デフォルト: true）
    # @option options [Boolean] :validate_security セキュリティ検証を実行（デフォルト: true）
    # @return [String] 処理済みテキスト
    def process_ai_text(text, options = {})
      return "" if text.blank?

      # デフォルトオプション
      opts = {
        sanitize: true,
        format_newlines: true,
        validate_security: true
      }.merge(options)

      processed_text = text.to_s.strip

      # セキュリティ検証（処理前）
      validate_input_security(processed_text) if opts[:validate_security]

      # セキュリティサニタイゼーション
      processed_text = TextSanitizer.sanitize_ai_output(processed_text) if opts[:sanitize]

      # 改行フォーマット処理
      processed_text = format_newlines_for_display(processed_text) if opts[:format_newlines]

      processed_text
    end

    # AI生成テキストに適した改行フォーマット
    # TILテキスト専用の改行処理（文ごとの改行を維持）
    # @param text [String] フォーマット対象のテキスト
    # @return [String] フォーマット済みテキスト
    def format_newlines_for_display(text)
      return text if text.blank?

      # 既存の改行文字を保持しつつ正規化
      formatted = TextSanitizer.normalize_newlines(text)

      # 文末の改行が不足している場合の補完
      ensure_sentence_breaks(formatted)
    end

    # 文ごとの改行確保（AIサービスの出力形式に合わせて）
    # @param text [String] 処理対象のテキスト
    # @return [String] 改行が適切に配置されたテキスト
    def ensure_sentence_breaks(text)
      return text if text.blank?

      # 文末記号の後に改行がない場合の補完
      text.gsub(/([。！？])\s*(?!\n)/, "\\1\n")
          .gsub(/\n+/, "\n") # 重複改行の整理
          .strip
    end

    # プロンプトインジェクション対策を含む入力検証
    # @param text [String] 検証対象のテキスト
    # @raise [SecurityError] セキュリティ違反を検出した場合
    def validate_input_security(text)
      return if TextSanitizer.safe_text?(text)

      Rails.logger.error("Unsafe AI output detected: #{text[0, 100]}...")
      raise SecurityError, "AI output failed security validation"
    end

    # 表示用の安全な改行処理
    # ViewヘルパーやPartialで使用するためのHTML安全な改行処理
    # @param text [String] 処理対象のテキスト
    # @return [ActiveSupport::SafeBuffer] HTML安全な改行処理済みテキスト
    def safe_join_with_breaks(text)
      return "".html_safe if text.blank?

      # 直接サニタイゼーションを実行（再帰を避ける）
      sanitized_text = TextSanitizer.sanitize_ai_output(text)

      # 改行文字で分割してHTML安全な結合
      lines = sanitized_text.split("\n")
      # safe_joinとtagヘルパーを直接実装して依存を排除
      escaped_lines = lines.map { |line| ERB::Util.html_escape(line) }
      escaped_lines.join("<br>".html_safe).html_safe
    end

    # デバッグ用のテキスト情報表示
    # @param text [String] 分析対象のテキスト
    # @return [Hash] テキスト情報
    def analyze_text(text)
      return { empty: true } if text.blank?

      {
        length: text.length,
        lines: text.count("\n") + 1,
        safe: TextSanitizer.safe_text?(text),
        has_dangerous_patterns: TextSanitizer::DANGEROUS_PATTERNS.any? { |pattern| text.match?(pattern) },
        has_injection_patterns: TextSanitizer::PROMPT_INJECTION_PATTERNS.any? { |pattern| text.match?(pattern) }
      }
    end
  end
end
