import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Object,
    options: Object
  }

  connect() {
    console.log("Heatmap controller connected")
    this.renderHeatmap()
  }

  renderHeatmap() {
    const weekdayData = this.dataValue.weekday_data
    const weekdayLabels = this.dataValue.weekday_labels
    const weeksCount = this.dataValue.weeks_count
    
    console.log("Rendering new heatmap structure:", this.dataValue)
    
    // ヒートマップのHTMLを生成（縦：曜日、横：週）
    let heatmapHTML = `
      <div class="heatmap-container">
        <div class="heatmap-legend mb-4">
          <span class="text-sm text-base-content/70">学習強度: </span>
          <div class="inline-flex items-center gap-1">
            <span class="text-xs text-base-content/50">低</span>
            ${this.generateLegendColors()}
            <span class="text-xs text-base-content/50">高</span>
          </div>
        </div>
        <div class="heatmap-grid">
          ${this.renderWeekdayRows(weekdayData, weekdayLabels, weeksCount)}
        </div>
      </div>
    `
    
    this.element.innerHTML = heatmapHTML
    this.addStyles()
  }

  renderWeekdayRows(weekdayData, weekdayLabels, weeksCount) {
    return weekdayLabels.map((label, wday) => {
      const dayData = weekdayData[wday] || []
      return `
        <div class="heatmap-row">
          <div class="weekday-label">${label}</div>
          <div class="weeks-container">
            ${dayData.map(day => this.renderDay(day)).join('')}
          </div>
        </div>
      `
    }).join('')
  }

  renderDay(day) {
    const color = this.getIntensityColor(day.intensity)
    const opacity = day.is_in_range && !day.is_future ? 1.0 : 0.3
    
    return `
      <div class="heatmap-day" 
           style="background-color: ${color}; opacity: ${opacity};"
           title="${day.date} - 強度: ${day.intensity}"
           data-date="${day.date}"
           data-intensity="${day.intensity}">
      </div>
    `
  }

  getIntensityColor(intensity) {
    if (intensity === 0) return '#ebedf0' // GitHub風グレー
    if (intensity <= 1) return '#9be9a8'  // 薄緑
    if (intensity <= 2) return '#40c463'  // 緑
    if (intensity <= 3) return '#30a14e'  // 濃緑
    return '#216e39'                      // 最高強度
  }

  generateLegendColors() {
    const colors = ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39']
    return colors.map(color => 
      `<div class="legend-color" style="background-color: ${color}"></div>`
    ).join('')
  }

  addStyles() {
    if (document.getElementById('heatmap-styles')) return
    
    const styles = `
      <style id="heatmap-styles">
        .heatmap-container {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        .heatmap-grid {
          display: flex;
          flex-direction: column;
          border-radius: 6px;
          overflow: hidden;
          gap: 2px;
        }
        .heatmap-row {
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .weekday-label {
          width: 20px;
          font-size: 11px;
          text-align: right;
          color: oklch(var(--bc) / 0.6);
          font-weight: 500;
        }
        .weeks-container {
          display: flex;
          gap: 2px;
        }
        .heatmap-day {
          width: 12px;
          height: 12px;
          border-radius: 2px;
          cursor: pointer;
          transition: all 0.2s;
          border: 1px solid rgba(0, 0, 0, 0.1);
        }
        .heatmap-day:hover {
          transform: scale(1.2);
          outline: 2px solid oklch(var(--p));
          z-index: 10;
          position: relative;
        }
        .legend-color {
          width: 12px;
          height: 12px;
          border-radius: 2px;
          margin: 0 1px;
          border: 1px solid rgba(0, 0, 0, 0.1);
        }
        .heatmap-legend {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 12px;
          justify-content: center;
        }
      </style>
    `
    document.head.insertAdjacentHTML('beforeend', styles)
  }

  disconnect() {
    // スタイルは他のヒートマップでも使うので削除しない
  }
}