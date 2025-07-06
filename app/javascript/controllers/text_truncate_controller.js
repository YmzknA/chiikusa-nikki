import { Controller } from "@hotwired/stimulus"
import { TextProcessor } from "../utils/text_processor"

export default class extends Controller {
  static targets = ["content", "button", "fullText", "topButton"]
  static values = { 
    maxLength: { type: Number, default: TextProcessor.getConfig('DEFAULT_MAX_LENGTH') },
    expanded: { type: Boolean, default: false },
    readMoreText: { type: String, default: '続きを読む' },
    closeText: { type: String, default: '閉じる' },
    errorMessage: { type: String, default: 'テキストの表示中にエラーが発生しました。' }
  }

  // エラーメッセージ
  static ERROR_MESSAGES = {
    INIT_FAILED: 'テキストの初期化に失敗しました。',
    DISPLAY_FAILED: 'テキストの表示更新に失敗しました。',
    PROCESSING_FAILED: 'テキストの処理に失敗しました。'
  }

  connect() {
    if (TextProcessor.getConfig('ENABLE_DEBUG_LOGGING')) {
      console.log("TextTruncateController connected")
    }
    this.initializeTruncation()
  }

  disconnect() {
    // クリーンアップ処理
    if (TextProcessor.getConfig('ENABLE_DEBUG_LOGGING')) {
      console.log("TextTruncateController disconnected")
    }
  }

  initializeTruncation() {
    try {
      const fullText = TextProcessor.getSafeTextFromElement(this.fullTextTarget)
      
      if (!fullText) {
        this.showError(this.constructor.ERROR_MESSAGES.INIT_FAILED)
        return
      }
      
      if (fullText.length <= this.maxLengthValue) {
        // テキストが短い場合はボタンを非表示
        this.hideButtons()
        TextProcessor.setSafeTextToElement(this.contentTarget, fullText)
        return
      }

      // 初期状態では短縮版を表示
      this.updateDisplay()
    } catch (error) {
      console.error('TextTruncateController initialization failed:', error)
      this.showError(this.constructor.ERROR_MESSAGES.INIT_FAILED)
    }
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.updateDisplay()
  }

  updateDisplay() {
    try {
      const fullText = TextProcessor.getSafeTextFromElement(this.fullTextTarget)
      
      if (!fullText) {
        this.showError(this.constructor.ERROR_MESSAGES.DISPLAY_FAILED)
        return
      }
      
      if (this.expandedValue) {
        this.showExpanded(fullText)
      } else {
        this.showTruncated(fullText)
      }
    } catch (error) {
      console.error('TextTruncateController display update failed:', error)
      this.showError(this.constructor.ERROR_MESSAGES.DISPLAY_FAILED)
    }
  }

  showExpanded(fullText) {
    TextProcessor.setSafeTextToElement(this.contentTarget, fullText)
    this.buttonTarget.textContent = this.closeTextValue
    this.buttonTarget.classList.remove("mt-1")
    this.buttonTarget.classList.add("mt-2")
    
    // 上部の閉じるボタンを表示
    if (this.hasTopButtonTarget) {
      this.topButtonTarget.style.display = 'block'
      this.topButtonTarget.textContent = this.closeTextValue
    }
  }

  showTruncated(fullText) {
    const truncatedText = TextProcessor.truncateText(fullText, this.maxLengthValue)
    TextProcessor.setSafeTextToElement(this.contentTarget, truncatedText)
    this.buttonTarget.textContent = this.readMoreTextValue
    this.buttonTarget.classList.remove("mt-2")
    this.buttonTarget.classList.add("mt-0.5")
    
    // 上部の閉じるボタンを非表示
    if (this.hasTopButtonTarget) {
      this.topButtonTarget.style.display = 'none'
    }
  }

  // ヘルパーメソッド
  hideButtons() {
    this.buttonTarget.style.display = 'none'
    if (this.hasTopButtonTarget) {
      this.topButtonTarget.style.display = 'none'
    }
  }

  showError(message) {
    const errorMessage = message || this.errorMessageValue
    TextProcessor.setSafeTextToElement(this.contentTarget, errorMessage)
    this.hideButtons()
  }

  // デバッグメソッド（開発環境のみ）
  debugText(text) {
    if (TextProcessor.getConfig('ENABLE_DEBUG_LOGGING')) {
      console.log('TextTruncateController debug:', TextProcessor.analyzeText(text))
    }
  }
}