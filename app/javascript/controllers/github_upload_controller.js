import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form"]
  
  connect() {
  }

  showConfirmation(event) {
    event.preventDefault()
    this.modalTarget.showModal()
  }

  confirm() {
    this.formTarget.submit()
  }

  cancel() {
    this.modalTarget.close()
  }
}