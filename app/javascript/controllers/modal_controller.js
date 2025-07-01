import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    console.log("Modal controller connected")
  }

  show() {
    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
    }
  }

  close() {
    if (this.hasDialogTarget) {
      this.dialogTarget.close()
    }
  }
}