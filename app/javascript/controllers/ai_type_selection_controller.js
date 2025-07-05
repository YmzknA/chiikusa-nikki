import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "label", "button"]
  static values = { triggerCheckboxId: String }

  connect() {
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

      const elements = this.getTargetElements()
      
      this.updateRadioStates(elements.radios, isEnabled)
      this.updateLabelStates(elements.labels, isEnabled)
      this.updateButtonStates(elements.buttons, isEnabled)
      
    } catch (error) {
      console.error("Error in updateState:", error)
    }
  }

  getTargetElements() {
    return {
      radios: this.radioTargets?.length > 0 ? this.radioTargets : this.element.querySelectorAll('[data-ai-type-selection-target="radio"]'),
      labels: this.labelTargets?.length > 0 ? this.labelTargets : this.element.querySelectorAll('[data-ai-type-selection-target="label"]'),
      buttons: this.buttonTargets?.length > 0 ? this.buttonTargets : this.element.querySelectorAll('[data-ai-type-selection-target="button"]')
    }
  }

  updateRadioStates(radios, isEnabled) {
    radios.forEach(radio => {
      radio.disabled = !isEnabled
    })
  }

  updateLabelStates(labels, isEnabled) {
    labels.forEach(label => {
      if (isEnabled) {
        label.classList.remove('cursor-not-allowed', 'pointer-events-none')
        label.classList.add('cursor-pointer')
      } else {
        label.classList.remove('cursor-pointer')
        label.classList.add('cursor-not-allowed', 'pointer-events-none')
      }
    })
  }

  updateButtonStates(buttons, isEnabled) {
    buttons.forEach(button => {
      if (isEnabled) {
        button.classList.remove('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
        button.classList.add('hover:scale-102')
      } else {
        button.classList.remove('hover:scale-102')
        button.classList.add('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
      }
    })
  }

  // 外部から呼び出し可能なメソッド（種不足モーダル用）
  disable() {
    const elements = this.getTargetElements()
    
    this.updateRadioStates(elements.radios, false)
    this.updateLabelStates(elements.labels, false)
    this.updateButtonStates(elements.buttons, false)
  }

}