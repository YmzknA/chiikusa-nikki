import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]
  static values = { delay: Number }
  
  connect() {
    console.log("🔄 Loading controller connected")
    this.delayValue = this.delayValue || 150
    this.timeout = null
    
    // このコントローラーインスタンスをグローバルに保存
    window.loadingController = this
    
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
    window.loadingController = null
  }
  
  // グローバルからアクセスできるように静的メソッドを追加
  static showLoading() {
    if (window.loadingController) {
      window.loadingController.showDelayed()
    }
  }
  
  // クリックイベントから呼び出される
  showOnClick(event) {
    console.log('🖱️ showOnClick triggered', event.currentTarget)
    // フォーム送信やリンククリックの場合のみローディング表示
    const element = event.currentTarget
    if (element.tagName === 'A' || element.tagName === 'BUTTON' || element.closest('form')) {
      console.log('✅ showOnClick conditions met, calling showDelayed')
      this.showDelayed()
    } else {
      console.log('❌ showOnClick conditions not met')
    }
  }
  
  // フォーム送信時に呼び出される
  showOnSubmit(event) {
    console.log('📝 showOnSubmit triggered', event.currentTarget)
    this.showDelayed()
  }
  
  showDelayed() {
    console.log('⏱️ showDelayed called, hasSpinnerTarget:', this.hasSpinnerTarget)
    if (!this.hasSpinnerTarget) {
      console.log('❌ No spinner target found')
      return
    }
    
    console.log('⏰ Setting timeout with delay:', this.delayValue)
    this.timeout = setTimeout(() => {
      console.log('⏰ Timeout fired, calling show()')
      this.show()
    }, this.delayValue)
  }
  
  show() {
    console.log('👁️ show() called, hasSpinnerTarget:', this.hasSpinnerTarget)
    if (!this.hasSpinnerTarget) {
      console.log('❌ No spinner target in show()')
      return
    }
    console.log('✨ Showing loading spinner')
    this.spinnerTarget.classList.remove("hidden")
    this.spinnerTarget.classList.add("flex")
  }
  
  hide() {
    console.log('🙈 hide() called')
    if (this.timeout) {
      console.log('⏰ Clearing timeout')
      clearTimeout(this.timeout)
      this.timeout = null
    }
    
    if (!this.hasSpinnerTarget) {
      console.log('❌ No spinner target in hide()')
      return
    }
    console.log('✨ Hiding loading spinner')
    this.spinnerTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("flex")
  }
}