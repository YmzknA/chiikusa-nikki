import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    console.log("Reaction stats controller connected")
  }

  disconnect() {
    console.log("Reaction stats controller disconnected")
  }

  showModal(event) {
    console.log("Showing reaction stats modal")
    this.modalTarget.showModal()
  }

  hideModal(event) {
    console.log("Hiding reaction stats modal")
    this.modalTarget.close()
  }

  stopPropagation(event) {
    // モーダル内のクリックで背景クリックによる閉じる動作を阻止
    event.stopPropagation()
  }
}