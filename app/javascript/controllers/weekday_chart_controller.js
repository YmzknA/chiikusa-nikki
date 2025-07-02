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
    
    const canvas = this.hasCanvasTarget ? this.canvasTarget : this.element.querySelector('canvas')
    if (!canvas) {
      console.error("Canvas element not found")
      return
    }
    
    // カスタムツールチップを設定
    const customOptions = {
      ...this.defaultOptions,
      ...this.optionsValue,
      plugins: {
        ...this.optionsValue.plugins,
        tooltip: {
          ...this.optionsValue.plugins.tooltip,
          callbacks: {
            title: (context) => {
              return context[0].label + '曜日の平均値'
            },
            label: (context) => {
              const dataset = context.dataset
              const dataIndex = context.dataIndex
              const value = context.parsed.y
              const count = dataset.counts ? dataset.counts[dataIndex] : 0
              return dataset.label + ': Lv.' + value.toFixed(1) + ' (平均)'
            },
            afterBody: (context) => {
              const dataset = context[0].dataset
              const dataIndex = context[0].dataIndex
              const count = dataset.counts ? dataset.counts[dataIndex] : 0
              return '記録数: ' + count + '日'
            }
          }
        }
      }
    }
    
    try {
      this.chart = new Chart(canvas.getContext('2d'), {
        type: this.typeValue || 'bar',
        data: this.dataValue || { labels: [], datasets: [] },
        options: customOptions
      })
    } catch (error) {
      console.error("Weekday chart creation failed:", error)
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = undefined
    }
  }

  get defaultOptions() {
    return {
      responsive: true,
      maintainAspectRatio: false
    }
  }
}