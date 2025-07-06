import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileModal", "mobileModalContent", "desktopModal", "modalEmojiContent"]

  connect() {
    console.log("Reaction modal controller connected")
    // バインドしたハンドラーを保存してdisconnect時に適切に削除できるようにする
    this.boundHandleShowModal = this.handleShowModal.bind(this)
    document.addEventListener("reaction:show-modal", this.boundHandleShowModal)
  }

  disconnect() {
    console.log("Reaction modal controller disconnected")
    // 適切にイベントリスナーを削除
    if (this.boundHandleShowModal) {
      document.removeEventListener("reaction:show-modal", this.boundHandleShowModal)
      this.boundHandleShowModal = null
    }
  }

  handleShowModal(event) {
    const diaryId = event.detail.diaryId
    this.currentDiaryId = diaryId
    this.loadEmojiContent(diaryId)
    this.showModal()
  }

  async loadEmojiContent(diaryId) {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 5000)

    try {
      // サーバーから絵文字コンテンツを取得
      const response = await fetch(`/diaries/${diaryId}/reaction_modal_content`, {
        signal: controller.signal
      })
      clearTimeout(timeoutId)
      
      if (response.ok) {
        const html = await response.text()
        this.modalEmojiContentTargets.forEach(target => {
          target.innerHTML = html
        })
      }
    } catch (error) {
      clearTimeout(timeoutId)
      if (error.name === 'AbortError') {
        console.error('Request timeout')
      }
      console.error("Failed to load emoji content:", error)
    }
  }

  showModal() {
    if (window.innerWidth < 768) { // md breakpoint
      // スマホサイズ: 下から伸びてくるモーダル
      this.mobileModalTarget.classList.remove("hidden")
      
      requestAnimationFrame(() => {
        this.mobileModalContentTarget.setAttribute("data-modal-visible", "true")
      })
    } else {
      // デスクトップサイズ: 従来通りの中央表示
      if (this.hasDesktopModalTarget) {
        this.desktopModalTarget.classList.remove("hidden")
        this.desktopModalTarget.classList.add("flex")
      }
    }
  }

  hideModal() {
    if (window.innerWidth < 768) { // md breakpoint
      // スマホサイズ: アニメーション終了を待つ
      this.mobileModalContentTarget.removeAttribute("data-modal-visible")

      setTimeout(() => {
        this.mobileModalTarget.classList.add("hidden")
      }, 300) // transition-duration と合わせる
    } else {
      // デスクトップサイズ: 即座に非表示
      if (this.hasDesktopModalTarget) {
        this.desktopModalTarget.classList.add("hidden")
        this.desktopModalTarget.classList.remove("flex")
      }
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
