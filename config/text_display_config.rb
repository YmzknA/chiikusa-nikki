# frozen_string_literal: true

# テキスト表示機能の設定値一元管理
# UI表示、AI生成テキスト、セキュリティ設定の統合管理
module TextDisplayConfig
  # テキスト切り詰め設定
  module Truncation
    # デフォルトの最大表示文字数
    DEFAULT_MAX_LENGTH = 150
    
    # 短文表示用の最大文字数
    SHORT_MAX_LENGTH = 100
    
    # 長文表示用の最大文字数
    LONG_MAX_LENGTH = 300
    
    # 単語境界判定時の最小比率
    # 最大長の80%以上の位置で単語境界がある場合、そこで切り詰める
    WORD_BOUNDARY_RATIO = 0.8
    
    # 切り詰め時の省略記号
    TRUNCATE_SUFFIX = '...'
    
    # 切り詰め対象となる文字（日本語対応）
    TRUNCATE_BOUNDARIES = [' ', "\n", '。', '、', '！', '？', '：', '；'].freeze
  end

  # AI生成テキスト設定
  module AIText
    # AI生成テキストの最大許可文字数（セキュリティ対策）
    MAX_ALLOWED_LENGTH = 5000
    
    # AI生成テキストの最大許可改行数（DoS対策）
    MAX_ALLOWED_LINES = 100
    
    # AI生成テキストの最小文字数（品質チェック）
    MIN_REQUIRED_LENGTH = 10
    
    # 1文あたりの推奨最大文字数
    RECOMMENDED_SENTENCE_LENGTH = 50
    
    # 生成されたTIL候補の最大数
    MAX_TIL_CANDIDATES = 3
  end

  # セキュリティ設定
  module Security
    # XSS対策: HTMLタグの許可・禁止設定
    ALLOWED_HTML_TAGS = %w[br p strong em].freeze
    FORBIDDEN_HTML_TAGS = %w[script iframe object embed form input].freeze
    
    # プロンプトインジェクション検出時の対応
    INJECTION_DETECTION_ACTION = :raise_error # :raise_error, :log_only, :sanitize
    
    # 危険なパターン検出時の対応
    DANGEROUS_PATTERN_ACTION = :sanitize # :sanitize, :raise_error, :log_only
    
    # セキュリティログの出力レベル
    SECURITY_LOG_LEVEL = :error
  end

  # UI表示設定
  module Display
    # 「続きを読む」ボタンのテキスト
    READ_MORE_TEXT = '続きを読む'
    
    # 「閉じる」ボタンのテキスト
    CLOSE_TEXT = '閉じる'
    
    # 上部閉じるボタンのテキスト
    TOP_CLOSE_TEXT = '閉じる ↑'
    
    # 下部続きを読むボタンのテキスト
    BOTTOM_READ_MORE_TEXT = '続きを読む ↓'
    
    # エラーメッセージ
    ERROR_MESSAGE = 'テキストの表示中にエラーが発生しました。'
    
    # 読み込み中メッセージ
    LOADING_MESSAGE = '読み込み中...'
    
    # テキストが見つからない場合のメッセージ
    NO_TEXT_MESSAGE = '表示するテキストがありません。'
  end

  # パフォーマンス設定
  module Performance
    # DOM更新の最大頻度（ミリ秒）
    MAX_UPDATE_FREQUENCY = 100
    
    # 大量テキスト処理時のチャンクサイズ
    LARGE_TEXT_CHUNK_SIZE = 1000
    
    # 大量テキストの閾値
    LARGE_TEXT_THRESHOLD = 5000
    
    # JavaScript処理タイムアウト（ミリ秒）
    JS_PROCESSING_TIMEOUT = 5000
  end

  # 開発・デバッグ設定
  module Debug
    # デバッグモードの有効/無効
    ENABLE_DEBUG_LOGGING = Rails.env.development?
    
    # パフォーマンス監視の有効/無効
    ENABLE_PERFORMANCE_MONITORING = Rails.env.development?
    
    # セキュリティテストの有効/無効
    ENABLE_SECURITY_TESTING = Rails.env.development? || Rails.env.test?
  end

  # 環境別設定の取得
  class << self
    # 現在の環境に応じた設定値を取得
    # @param key [Symbol] 設定キー
    # @param default [Object] デフォルト値
    # @return [Object] 設定値
    def get(key, default = nil)
      case key
      when :max_length
        ENV.fetch('TEXT_MAX_LENGTH', Truncation::DEFAULT_MAX_LENGTH).to_i
      when :word_boundary_ratio
        ENV.fetch('WORD_BOUNDARY_RATIO', Truncation::WORD_BOUNDARY_RATIO).to_f
      when :ai_max_length
        ENV.fetch('AI_MAX_LENGTH', AIText::MAX_ALLOWED_LENGTH).to_i
      when :security_level
        ENV.fetch('SECURITY_LEVEL', 'strict').to_sym
      else
        default
      end
    end

    # 設定値の検証
    # @param key [Symbol] 設定キー
    # @param value [Object] 設定値
    # @return [Boolean] 有効な設定値の場合true
    def valid_config?(key, value)
      case key
      when :max_length
        value.is_a?(Integer) && value > 0 && value <= 1000
      when :word_boundary_ratio
        value.is_a?(Float) && value > 0.0 && value <= 1.0
      when :ai_max_length
        value.is_a?(Integer) && value > 0 && value <= 10000
      else
        true
      end
    end
  end
end