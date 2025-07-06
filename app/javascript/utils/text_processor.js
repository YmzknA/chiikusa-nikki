// テキスト処理ユーティリティクラス
// Stimulusコントローラーからテキスト処理ロジックを分離
export class TextProcessor {
  // 設定値（Rails側の設定と同期）
  static CONFIG = {
    TEXT_DEFAULT_LENGTH: 150,
    WORD_BOUNDARY_RATIO: 0.8,
    TRUNCATE_SUFFIX: '...',
    TRUNCATE_BOUNDARIES: [' ', '\n', '。', '、', '！', '？', '：', '；'],
    TEXT_MAX_PROCESSING_TIME: 5000, // 5秒のタイムアウト
    ENABLE_DEBUG_LOGGING: document.documentElement.dataset.railsEnv === 'development'
  }

  /**
   * テキストを指定された長さで切り詰める
   * 単語境界や句読点を考慮して自然な位置で切り詰める
   * @param {string} text - 切り詰める対象のテキスト
   * @param {number} maxLength - 最大文字数
   * @returns {string} 切り詰められたテキスト
   */
  static truncateText(text, maxLength = this.CONFIG.TEXT_DEFAULT_LENGTH) {
    if (!text || typeof text !== 'string') {
      console.warn('TextProcessor.truncateText: Invalid text input')
      return ''
    }

    if (text.length <= maxLength) {
      return text
    }

    try {
      // 処理時間の監視
      const startTime = performance.now()
      
      // 最後の区切り文字で切り取り、見栄えを良くする
      let truncated = text.slice(0, maxLength)
      
      // 各区切り文字の位置を取得
      const boundaryPositions = this.CONFIG.TRUNCATE_BOUNDARIES.map(boundary => 
        truncated.lastIndexOf(boundary)
      ).filter(pos => pos !== -1)
      
      // 最も後ろの区切り文字位置を取得
      const lastBoundary = Math.max(...boundaryPositions, -1)
      
      // 単語境界が最大長の設定比率以上の位置にある場合、そこで切り詰める
      if (lastBoundary > maxLength * this.CONFIG.WORD_BOUNDARY_RATIO) {
        truncated = truncated.slice(0, lastBoundary)
      }
      
      // 処理時間チェック
      const processingTime = performance.now() - startTime
      if (processingTime > this.CONFIG.TEXT_MAX_PROCESSING_TIME) {
        console.warn(`TextProcessor.truncateText: Processing took too long (${processingTime}ms)`)
      }
      
      return truncated.trim() + this.CONFIG.TRUNCATE_SUFFIX
    } catch (error) {
      console.error('TextProcessor.truncateText: Error during processing', error)
      // フォールバック処理
      return text.slice(0, maxLength) + this.CONFIG.TRUNCATE_SUFFIX
    }
  }

  /**
   * テキストの安全性をチェック
   * @param {string} text - チェック対象のテキスト
   * @returns {boolean} 安全な場合はtrue
   */
  static isTextSafe(text) {
    if (!text || typeof text !== 'string') {
      return false
    }

    // 基本的な長さチェック
    if (text.length > 10000) {
      return false
    }

    // 危険なパターンのチェック（基本的なもの）
    const dangerousPatterns = [
      /<script[^>]*>/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /<iframe[^>]*>/i
    ]

    return !dangerousPatterns.some(pattern => pattern.test(text))
  }

  /**
   * HTML要素から安全にテキストを取得
   * @param {HTMLElement} element - 対象要素
   * @returns {string} 取得したテキスト
   */
  static getSafeTextFromElement(element) {
    if (!element || !element.innerHTML) {
      return ''
    }

    try {
      // HTMLを取得し、基本的なサニタイゼーションを実行
      const html = element.innerHTML.trim()
      
      // 安全性チェック
      if (!this.isTextSafe(html)) {
        console.warn('TextProcessor.getSafeTextFromElement: Unsafe content detected')
        return ''
      }

      return html
    } catch (error) {
      console.error('TextProcessor.getSafeTextFromElement: Error getting text', error)
      return ''
    }
  }

  /**
   * DOM要素への安全なテキスト設定
   * @param {HTMLElement} element - 対象要素
   * @param {string} text - 設定するテキスト
   */
  static setSafeTextToElement(element, text) {
    if (!element) {
      console.warn('TextProcessor.setSafeTextToElement: Invalid element')
      return
    }

    try {
      // 安全性チェック
      if (!this.isTextSafe(text)) {
        console.warn('TextProcessor.setSafeTextToElement: Unsafe text detected')
        element.innerHTML = 'テキストの表示中にエラーが発生しました。'
        return
      }

      element.innerHTML = text || ''
    } catch (error) {
      console.error('TextProcessor.setSafeTextToElement: Error setting text', error)
      element.innerHTML = 'テキストの表示中にエラーが発生しました。'
    }
  }

  /**
   * 設定値の取得
   * @param {string} key - 設定キー
   * @returns {any} 設定値
   */
  static getConfig(key) {
    return this.CONFIG[key]
  }

  /**
   * デバッグ情報の出力
   * @param {string} text - 分析対象のテキスト
   * @returns {Object} デバッグ情報
   */
  static analyzeText(text) {
    if (!text || typeof text !== 'string') {
      return { valid: false, reason: 'Invalid input' }
    }

    return {
      valid: true,
      length: text.length,
      lines: text.split('\n').length,
      safe: this.isTextSafe(text),
      truncated: text.length > this.CONFIG.TEXT_DEFAULT_LENGTH
    }
  }
}