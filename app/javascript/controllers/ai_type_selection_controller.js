import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "label", "button"]
  static values = { triggerCheckboxId: String }

  connect() {
    console.log("AI Type Selection controller connected")
    // 少し遅延させて初期化
    setTimeout(() => this.updateState(), 100)
  }

  updateState() {
    try {
      const triggerCheckbox = document.getElementById(this.triggerCheckboxIdValue)
      
      if (!triggerCheckbox) {
        console.error("Trigger checkbox not found:", this.triggerCheckboxIdValue)
        return
      }

      const isEnabled = triggerCheckbox.checked
      console.log("AI Type Selection - isEnabled:", isEnabled)

      // ターゲットが見つからない場合は直接セレクタで取得
      const radios = this.radioTargets?.length > 0 ? this.radioTargets : this.element.querySelectorAll('[data-ai-type-selection-target="radio"]')
      const labels = this.labelTargets?.length > 0 ? this.labelTargets : this.element.querySelectorAll('[data-ai-type-selection-target="label"]')
      const buttons = this.buttonTargets?.length > 0 ? this.buttonTargets : this.element.querySelectorAll('[data-ai-type-selection-target="button"]')

      radios.forEach(radio => {
        radio.disabled = !isEnabled
      })

      labels.forEach(label => {
        if (isEnabled) {
          label.classList.remove('cursor-not-allowed', 'pointer-events-none')
          label.classList.add('cursor-pointer')
        } else {
          label.classList.remove('cursor-pointer')
          label.classList.add('cursor-not-allowed', 'pointer-events-none')
        }
      })

      buttons.forEach(button => {
        if (isEnabled) {
          button.classList.remove('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
          button.classList.add('hover:scale-102')
        } else {
          button.classList.remove('hover:scale-102')
          button.classList.add('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
        }
      })
      
    } catch (error) {
      console.error("Error in updateState:", error)
    }
  }

  // 外部から呼び出し可能なメソッド（種不足モーダル用）
  disable() {
    const radios = this.radioTargets?.length > 0 ? this.radioTargets : this.element.querySelectorAll('[data-ai-type-selection-target="radio"]')
    const labels = this.labelTargets?.length > 0 ? this.labelTargets : this.element.querySelectorAll('[data-ai-type-selection-target="label"]')
    const buttons = this.buttonTargets?.length > 0 ? this.buttonTargets : this.element.querySelectorAll('[data-ai-type-selection-target="button"]')

    radios.forEach(radio => {
      radio.disabled = true
    })

    labels.forEach(label => {
      label.classList.remove('cursor-pointer')
      label.classList.add('cursor-not-allowed', 'pointer-events-none')
    })

    buttons.forEach(button => {
      button.classList.remove('hover:scale-102')
      button.classList.add('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
    })
  }
}