import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "seedCount"]
  static values = { 
    url: String 
  }

  connect() {
    console.log("Water effect controller connected")
  }

  // 水やりボタンクリック時の処理
  async water(event) {
    event.preventDefault()
    console.log("Water button clicked, triggering effect")
    
    // エフェクトを即座に実行
    this.createWaterSplashEffect()
    
    // 少し遅らせてからサーバーリクエスト
    setTimeout(() => {
      this.submitWaterRequest()
    }, 300)
  }

  async onlyWater(event) {
    event.preventDefault()
    console.log("Only water button clicked, triggering effect")
    
    // エフェクトを即座に実行
    this.createWaterSplashEffect()
  }

  // 水しぶきエフェクトの作成
  createWaterSplashEffect() {
    const button = this.buttonTarget
    console.log("Creating water splash effect for button:", button)
    
    if (!button) {
      console.error("No button target found for water effect")
      return
    }
    
    // ボタンにアニメーションクラスを追加
    button.classList.add('water-button-animate')
    
    // 水しぶきエフェクトを作成
    const splash = document.createElement('div')
    splash.className = 'water-splash'
    
    // 6個の水滴を作成
    for (let i = 0; i < 6; i++) {
      const drop = document.createElement('div')
      drop.className = 'water-drop'
      
      // ランダムな方向設定
      const angle = (i * 60 + Math.random() * 30) * Math.PI / 180
      const distance = 20 + Math.random() * 15
      const dx = Math.cos(angle) * distance
      const dy = Math.sin(angle) * distance
      
      drop.style.setProperty('--dx', `${dx}px`)
      drop.style.setProperty('--dy', `${dy}px`)
      
      splash.appendChild(drop)
    }
    
    // ボタンの親要素に追加
    const container = button.parentNode
    container.style.position = 'relative'
    container.appendChild(splash)
    
    console.log("Water splash effect created and added to:", container)
    
    // エフェクト終了後にクリーンアップ
    setTimeout(() => {
      button.classList.remove('water-button-animate')
      if (splash.parentNode) {
        splash.parentNode.removeChild(splash)
      }
      console.log("Water effect cleaned up")
    }, 800)
  }

  // サーバーリクエストの送信
  async submitWaterRequest() {
    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })
      
      if (response.ok) {
        const turboStreamHtml = await response.text()
        Turbo.renderStreamMessage(turboStreamHtml)
      } else {
        console.error('Water request failed:', response.status)
      }
    } catch (error) {
      console.error('Error submitting water request:', error)
    }
  }

  // 成功時のエフェクト（外部から呼び出し可能）
  showSuccessEffect() {
    if (this.hasSeedCountTarget) {
      const counterContainer = this.seedCountTarget.closest('.neuro-card, .neuro-button-secondary')
      if (counterContainer) {
        counterContainer.classList.add('success-flash')
        setTimeout(() => {
          counterContainer.classList.remove('success-flash')
        }, 800)
      }
    }
  }
}
