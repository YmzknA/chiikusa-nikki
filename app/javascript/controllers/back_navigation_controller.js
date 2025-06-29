import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { fallbackUrl: String }

  connect() {
    console.log("Back navigation controller connected")
  }

  goBack(event) {
    event.preventDefault()
    
    // Check if there's previous page in the browser history
    // and if the previous page is from the same domain
    if (window.history.length > 1 && document.referrer && this.isSameDomain(document.referrer)) {
      // Navigate to the previous page
      window.history.back()
    } else {
      // Fallback to the default URL if no previous page or external referrer
      window.location.href = this.fallbackUrlValue
    }
  }

  isSameDomain(url) {
    try {
      const referrerUrl = new URL(url)
      const currentUrl = new URL(window.location.href)
      return referrerUrl.hostname === currentUrl.hostname
    } catch (error) {
      console.error('Error parsing URLs:', error)
      return false
    }
  }
}