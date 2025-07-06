import { Controller } from "@hotwired/stimulus"

// FlashController handles flash message interactions
export default class extends Controller {
  connect() {
    console.log("Flash controller connected")
  }

  disconnect() {
    console.log("Flash controller disconnected")
  }

  close(event) {
    event.preventDefault()
    const alertElement = event.currentTarget.closest('.alert')
    if (alertElement) {
      alertElement.remove()
    }
  }
}