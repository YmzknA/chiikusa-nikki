import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Controller connected
  }

  disconnect() {
    // Controller disconnected
  }

  showModal(event) {
    this.modalTarget.showModal()
  }

  hideModal(event) {
    this.modalTarget.close()
  }

  stopPropagation(event) {
    // モーダル内のクリックで背景クリックによる閉じる動作を阻止
    event.stopPropagation()
  }
}