import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]
  static values = { delay: Number }
  
  connect() {
    console.log("🤖 AI Loading controller connected")
    this.delayValue = this.delayValue || 150
    this.timeout = null
    
    // このコントローラーインスタンスをグローバルに保存
    window.aiLoadingController = this
    
    // Turboイベントをリッスン（ページ遷移完了時に自動的に隠す）
    document.addEventListener("turbo:load", this.hide.bind(this))
    document.addEventListener("turbo:frame-load", this.hide.bind(this))
    document.addEventListener("turbo:submit-end", this.hide.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("turbo:load", this.hide.bind(this))
    document.removeEventListener("turbo:frame-load", this.hide.bind(this))
    document.removeEventListener("turbo:submit-end", this.hide.bind(this))
    
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // グローバル参照をクリア
    window.aiLoadingController = null
  }
  
  // グローバルからアクセスできるように静的メソッドを追加
  static showAiLoading() {
    if (window.aiLoadingController) {
      window.aiLoadingController.showDelayed()
    }
  }
  
  // AI生成時に呼び出される
  showOnAiGeneration() {
    console.log('🤖 AI generation started')
    this.showDelayed()
  }
  
  showDelayed() {
    console.log('🤖 AI showDelayed called, hasSpinnerTarget:', this.hasSpinnerTarget)
    if (!this.hasSpinnerTarget) {
      console.log('❌ No AI spinner target found')
      return
    }
    
    console.log('⏰ Setting AI loading timeout with delay:', this.delayValue)
    this.timeout = setTimeout(() => {
      console.log('⏰ AI timeout fired, calling show()')
      this.show()
    }, this.delayValue)
  }
  
  show() {
    console.log('🤖 AI show() called, hasSpinnerTarget:', this.hasSpinnerTarget)
    if (!this.hasSpinnerTarget) {
      console.log('❌ No AI spinner target in show()')
      return
    }
    console.log('✨ Showing AI loading spinner')
    this.spinnerTarget.classList.remove("hidden")
    this.spinnerTarget.classList.add("flex")
  }
  
  hide() {
    console.log('🙈 AI hide() called')
    if (this.timeout) {
      console.log('⏰ Clearing AI timeout')
      clearTimeout(this.timeout)
      this.timeout = null
    }
    
    if (!this.hasSpinnerTarget) {
      console.log('❌ No AI spinner target in hide()')
      return
    }
    console.log('✨ Hiding AI loading spinner')
    this.spinnerTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("flex")
  }
}