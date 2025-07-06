import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "emojiButton", "selectedEmoji", "addButton"]
  static values = { 
    diaryId: Number,
    userReactions: Array,
    categories: Object
  }

  connect() {
    console.log("Reaction controller connected")
    this.updateEmojiDisplay()
  }

  showModal() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
  }

  hideModal() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  selectEmoji(event) {
    const emoji = event.currentTarget.dataset.emoji
    const isUserReaction = this.userReactionsValue.includes(emoji)

    if (isUserReaction) {
      this.removeReaction(emoji)
    } else {
      this.addReaction(emoji)
    }

    this.hideModal()
  }

  addReaction(emoji) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    
    fetch(`/diaries/${this.diaryIdValue}/reactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: JSON.stringify({ reaction: { emoji: emoji } })
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error adding reaction:', error)
    })
  }

  removeReaction(emoji) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    
    fetch(`/diaries/${this.diaryIdValue}/reactions/${emoji}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error removing reaction:', error)
    })
  }

  updateEmojiDisplay() {
    // Update emoji buttons to show user reactions with special styling
    this.emojiButtonTargets.forEach(button => {
      const emoji = button.dataset.emoji
      const isUserReaction = this.userReactionsValue.includes(emoji)
      
      if (isUserReaction) {
        button.classList.add('bg-blue-100', 'ring-2', 'ring-blue-300')
      } else {
        button.classList.remove('bg-blue-100', 'ring-2', 'ring-blue-300')
      }
    })
  }
}