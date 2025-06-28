import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    type: String,
    data: Object,
    options: Object
  }

  connect() {
    console.log("Chart debug controller connected")
    console.log("Type:", this.typeValue)
    console.log("Data:", this.dataValue)
    console.log("Options:", this.optionsValue)
    
    // Chart.jsが利用可能か確認
    console.log("Chart.js available:", typeof Chart)
    
    const canvas = this.hasCanvasTarget ? this.canvasTarget : this.element.querySelector('canvas')
    if (!canvas) {
      console.error("Canvas element not found")
      return
    }
    
    console.log("Canvas found:", canvas)
    
    try {
      this.chart = new Chart(canvas.getContext('2d'), {
        type: this.typeValue || 'line',
        data: this.dataValue || { labels: [], datasets: [] },
        options: {
          ...this.defaultOptions,
          ...this.optionsValue
        }
      })
      console.log("Chart created successfully:", this.chart)
    } catch (error) {
      console.error("Chart creation failed:", error)
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = undefined
      console.log("Chart destroyed")
    }
  }

  get defaultOptions() {
    return {
      responsive: true,
      maintainAspectRatio: false
    }
  }
}