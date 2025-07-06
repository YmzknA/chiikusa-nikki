import { Controller } from "@hotwired/stimulus"

// EventDispatcherController handles server-initiated event dispatch
// This controller provides a secure way to dispatch custom events from server responses
// without injecting JavaScript directly into the DOM
export default class extends Controller {
  static values = {
    eventName: String,
    targetId: String,
    detail: Object
  }

  connect() {
    console.log("EventDispatcher controller connected")
    // Automatically dispatch the event when the controller connects
    this.dispatch()
  }

  dispatch() {
    const eventName = this.eventNameValue
    const targetId = this.targetIdValue
    const detail = this.detailValue || {}

    if (!eventName) {
      console.error("EventDispatcher: eventName is required")
      return
    }

    // Find the target element
    const targetElement = targetId ? document.getElementById(targetId) : document

    if (!targetElement) {
      console.error(`EventDispatcher: Target element with id '${targetId}' not found`)
      return
    }

    // Create and dispatch the custom event
    const customEvent = new CustomEvent(eventName, {
      detail: detail,
      bubbles: true,
      cancelable: true
    })

    targetElement.dispatchEvent(customEvent)
    
    console.log(`EventDispatcher: Dispatched '${eventName}' event to '${targetId || 'document'}'`)
    
    // Clean up: remove the dispatcher element after dispatch
    this.element.remove()
  }
}