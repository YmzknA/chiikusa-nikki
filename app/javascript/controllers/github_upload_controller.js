import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form"]
  
  connect() {
    console.log("GitHub upload controller connected")
  }

  showConfirmation(event) {
    event.preventDefault()
    console.log("Showing GitHub upload confirmation")
    this.modalTarget.showModal()
  }

  confirm() {
    console.log("GitHub upload confirmed, submitting form")
    this.formTarget.submit()
  }

  cancel() {
    console.log("GitHub upload canceled")
    this.modalTarget.close()
  }
}