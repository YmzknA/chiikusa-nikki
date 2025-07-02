import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.forceLightTheme()
  }

  forceLightTheme() {
    // Force HTML element to use lemonade theme
    document.documentElement.setAttribute('data-theme', 'lemonade')
    document.documentElement.style.colorScheme = 'light'
    
    // Force body to inherit light mode
    document.body.style.colorScheme = 'light'
    
    // Prevent any theme switching
    localStorage.removeItem('theme')
    localStorage.removeItem('data-theme')
    
  }
}