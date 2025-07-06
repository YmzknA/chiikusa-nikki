import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]
  static values = { delay: Number }
  
  connect() {
    this.delayValue = this.delayValue || 150
    this.timeout = null
    
    // このコントローラーインスタンスをグローバルに保存
    window.aiLoadingController = this
    
    // バインドしたハンドラーを保存してdisconnect時に適切に削除できるようにする
    this.boundHide = this.hide.bind(this)
    
    // Turboイベントをリッスン（ページ遷移完了時に自動的に隠す）
    document.addEventListener("turbo:load", this.boundHide)
    document.addEventListener("turbo:frame-load", this.boundHide)
    document.addEventListener("turbo:submit-end", this.boundHide)
  }
  
  disconnect() {
    // 適切にイベントリスナーを削除
    if (this.boundHide) {
      document.removeEventListener("turbo:load", this.boundHide)
      document.removeEventListener("turbo:frame-load", this.boundHide)
      document.removeEventListener("turbo:submit-end", this.boundHide)
      this.boundHide = null
    }
    
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
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
    this.showDelayed()
  }
  
  showDelayed() {
    if (!this.hasSpinnerTarget) {
      return
    }
    
    this.timeout = setTimeout(() => {
      this.show()
    }, this.delayValue)
  }
  
  show() {
    if (!this.hasSpinnerTarget) {
      return
    }
    this.spinnerTarget.classList.remove("hidden")
    this.spinnerTarget.classList.add("flex")
  }
  
  hide() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    
    if (!this.hasSpinnerTarget) {
      return
    }
    this.spinnerTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("flex")
  }
}