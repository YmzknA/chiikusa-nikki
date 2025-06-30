import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]
  static values = { delay: Number }
  
  connect() {
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
    // フォーム送信やリンククリックの場合のみローディング表示
    const element = event.currentTarget
    if (element.tagName === 'A' || element.tagName === 'BUTTON' || element.closest('form')) {
      this.showDelayed()
    }
  }
  
  // フォーム送信時に呼び出される
  showOnSubmit(event) {
    this.showDelayed()
  }
  
  showDelayed() {
    if (!this.hasSpinnerTarget) return
    
    this.timeout = setTimeout(() => {
      this.show()
    }, this.delayValue)
  }
  
  show() {
    if (!this.hasSpinnerTarget) return
    this.spinnerTarget.classList.remove("hidden")
    this.spinnerTarget.classList.add("flex")
  }
  
  hide() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    
    if (!this.hasSpinnerTarget) return
    this.spinnerTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("flex")
  }
}