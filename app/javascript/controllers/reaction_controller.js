import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["desktopModal"]

  connect() {
    console.log("Reaction controller connected")
    // バインドしたハンドラーを保存
    this.boundHideModal = () => {
      this.hideModal()
    }
    // カスタムイベントを監視してモーダルを閉じる
    this.element.addEventListener("reaction:hide-modal", this.boundHideModal)
  }

  disconnect() {
    console.log("Reaction controller disconnected")
    // 適切にイベントリスナーを削除
    if (this.boundHideModal) {
      this.element.removeEventListener("reaction:hide-modal", this.boundHideModal)
      this.boundHideModal = null
    }
  }

  showModal(event) {
    const button = event.currentTarget
    const diaryId = button.dataset.diaryId
    
    if (window.innerWidth < 768) { // md breakpoint
      // スマホサイズ: ページレベルのモーダルにイベントを送信
      const modalEvent = new CustomEvent("reaction:show-modal", {
        detail: { diaryId: diaryId },
        bubbles: true
      })
      document.dispatchEvent(modalEvent)
    } else {
      // デスクトップサイズ: カード内のモーダルを表示
      if (this.hasDesktopModalTarget) {
        this.desktopModalTarget.classList.remove("hidden")
        this.desktopModalTarget.classList.add("flex")
      }
    }
  }

  hideModal() {
    // デスクトップサイズ: カード内のモーダルを閉じる
    if (this.hasDesktopModalTarget) {
      this.desktopModalTarget.classList.add("hidden")
      this.desktopModalTarget.classList.remove("flex")
    }
  }


  stopPropagation(event) {
    event.stopPropagation()
  }
}