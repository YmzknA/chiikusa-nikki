import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    diaryId: String,
    shareUrl: String 
  }

  connect() {
  }

  // X共有リンククリック時の処理
  async share(event) {
    
    // タネ獲得リクエストを並行して送信
    if (this.shareUrlValue) {
      this.requestSeedIncrement()
    }
    
    // リンクは通常通り動作（X投稿ページを開く）
    // event.preventDefault()は呼ばない
  }

  // タネ獲得リクエストの送信
  async requestSeedIncrement() {
    try {
      const formData = new FormData()
      formData.append('diary_id', this.diaryIdValue)
      
      const response = await fetch(this.shareUrlValue, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: formData
      })
      
      if (response.ok) {
        const turboStreamHtml = await response.text()
        Turbo.renderStreamMessage(turboStreamHtml)
      } else {
        console.error('Seed increment request failed:', response.status)
      }
    } catch (error) {
      console.error('Error requesting seed increment:', error)
    }
  }
}