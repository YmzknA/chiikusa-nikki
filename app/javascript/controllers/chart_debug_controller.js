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
    
    // カスタムツールチップを設定
    const customOptions = {
      ...this.defaultOptions,
      ...this.optionsValue
    }

    // 日毎推移チャートの場合、クリックイベントとホバーカーソルを追加
    if (this.typeValue === 'line' && this.dataValue.diary_ids) {
      customOptions.onClick = (event, elements) => {
        if (elements.length > 0) {
          const index = elements[0].index
          const diaryId = this.dataValue.diary_ids[index]
          if (diaryId) {
            window.location.href = `/diaries/${diaryId}`
          }
        }
      }
      
      customOptions.onHover = (event, elements) => {
        event.native.target.style.cursor = elements.length > 0 ? 'pointer' : 'default'
      }
    }

    // 日毎推移チャートの場合のツールチップカスタマイズ
    if (this.typeValue === 'line' && customOptions.plugins && customOptions.plugins.title && 
        (customOptions.plugins.title.text.includes('推移') || customOptions.plugins.title.text.includes('直近') || customOptions.plugins.title.text.includes('月の'))) {
      customOptions.plugins.tooltip = {
        ...customOptions.plugins.tooltip,
        backgroundColor: 'rgba(255, 255, 255, 0.95)',
        titleColor: '#333',
        bodyColor: '#666',
        borderColor: '#ddd',
        borderWidth: 1,
        cornerRadius: 8,
        callbacks: {
          title: (context) => {
            return context[0].label + 'の記録'
          },
          label: (context) => {
            const value = context.parsed.y
            if (value === null || value === undefined) {
              return context.dataset.label + ': 記録なし'
            }
            return context.dataset.label + ': レベル' + value
          },
          afterBody: (context) => {
            const hasData = context.some(item => item.parsed.y !== null && item.parsed.y !== undefined)
            if (!hasData) {
              return 'この日は日記を書いていません'
            }
            return ''
          }
        }
      }
    }
    
    try {
      this.chart = new Chart(canvas.getContext('2d'), {
        type: this.typeValue || 'line',
        data: this.dataValue || { labels: [], datasets: [] },
        options: customOptions
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