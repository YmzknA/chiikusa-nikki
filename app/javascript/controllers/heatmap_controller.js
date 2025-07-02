import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Object,
    options: Object
  }

  connect() {
    this.renderHeatmap()
    
    // 画面サイズ変更時の再描画
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
  }

  renderHeatmap() {
    const weekdayData = this.dataValue.weekday_data
    const weekdayLabels = this.dataValue.weekday_labels
    const weeksCount = this.dataValue.weeks_count
    
    // 画面幅をチェックして表示期間を調整
    const isMobile = window.innerWidth < 768
    const displayData = isMobile ? this.getMobileData(weekdayData, weeksCount) : { weekdayData, weeksCount }
    const displayTitle = "学習強度ヒートマップ（直近4ヶ月）"
    
    
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
        <div class="heatmap-wrapper">
          ${this.renderMonthHeaders(displayData.weekdayData, displayData.weeksCount)}
          <div class="heatmap-grid">
            ${this.renderWeekdayRows(displayData.weekdayData, weekdayLabels, displayData.weeksCount)}
          </div>
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
    const isToday = new Date(day.date).toDateString() === new Date().toDateString()
    const todayClass = isToday ? ' today' : ''
    
    return `
      <div class="heatmap-day${todayClass}" 
           style="background-color: ${color}; opacity: ${opacity};"
           title="${day.date} - 強度: ${day.intensity}"
           data-date="${day.date}"
           data-intensity="${day.intensity}"
           data-action="click->heatmap#navigateToDiary">
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
        .heatmap-wrapper {
          position: relative;
        }
        .month-headers {
          position: relative;
          height: 20px;
          margin-bottom: 4px;
        }
        .month-header {
          position: absolute;
          font-size: 11px;
          font-weight: 500;
          color: oklch(var(--bc) / 0.7);
          white-space: nowrap;
        }
        .heatmap-grid {
          display: flex;
          flex-direction: column;
          border-radius: 6px;
          overflow: hidden;
          gap: 2px;
          max-width: 100%;
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
          flex-wrap: wrap;
          justify-content: flex-start;
        }
        .heatmap-day {
          width: 12px;
          height: 12px;
          border-radius: 2px;
          cursor: pointer;
          transition: all 0.2s;
          border: 1px solid rgba(0, 0, 0, 0.1);
          min-width: 12px;
          flex-shrink: 0;
        }
        @media (max-width: 767px) {
          .heatmap-day {
            width: 10px;
            height: 10px;
            min-width: 10px;
          }
          .weekday-label {
            width: 16px;
            font-size: 10px;
          }
          .legend-color {
            width: 10px;
            height: 10px;
          }
          .month-header {
            font-size: 10px;
          }
        }
        .heatmap-day:hover {
          transform: scale(1.2);
          outline: 2px solid oklch(var(--p));
          z-index: 10;
          position: relative;
        }
        .heatmap-day.today {
          outline: 2px solid oklch(var(--p));
          outline-offset: 1px;
          box-shadow: 0 0 0 1px oklch(var(--p) / 0.3);
        }
        .heatmap-day.today:hover {
          outline: 3px solid oklch(var(--p));
          box-shadow: 0 0 0 2px oklch(var(--p) / 0.5);
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

  navigateToDiary(event) {
    const date = event.target.dataset.date
    const intensity = parseFloat(event.target.dataset.intensity)
    
    // 記録がある日のみ日記詳細に遷移
    if (intensity > 0) {
      // 日記詳細ページのURLを構築
      // 日記IDを取得するためにAJAXリクエストを送信するか、
      // または日付ベースの検索エンドポイントを作成する
      this.findDiaryByDate(date)
    } else {
      // 記録がない日は新規作成ページに遷移
      window.location.href = `/diaries/new?date=${date}`
    }
  }

  async findDiaryByDate(date) {
    try {
      const response = await fetch(`/diaries/search_by_date?date=${date}`)
      if (response.ok) {
        const data = await response.json()
        if (data.diary_id) {
          window.location.href = `/diaries/${data.diary_id}`
        } else {
          window.location.href = `/diaries/new?date=${date}`
        }
      }
    } catch (error) {
      console.error('Error finding diary:', error)
      window.location.href = `/diaries/new?date=${date}`
    }
  }

  renderMonthHeaders(weekdayData, weeksCount) {
    if (!weekdayData[0] || weekdayData[0].length === 0) return ''
    
    let monthHeaders = ''
    let currentMonth = null
    const isMobile = window.innerWidth < 768
    const daySize = isMobile ? 10 : 12
    const gap = 2
    const labelWidth = isMobile ? 16 : 20
    
    for (let weekIndex = 0; weekIndex < weeksCount; weekIndex++) {
      // 各週の最初の日（日曜日）の日付を取得
      const weekData = weekdayData[0][weekIndex]
      if (!weekData) continue
      
      const date = new Date(weekData.date)
      const month = date.getMonth()
      
      if (currentMonth !== month) {
        const monthName = date.toLocaleDateString('en-US', { month: 'short' })
        const leftPosition = labelWidth + 8 + weekIndex * (daySize + gap)
        monthHeaders += `
          <div class="month-header" style="left: ${leftPosition}px;">
            ${monthName}
          </div>
        `
        currentMonth = month
      }
    }
    
    return `<div class="month-headers">${monthHeaders}</div>`
  }

  getMobileData(weekdayData, totalWeeksCount) {
    // 4ヶ月分（約17週）のデータのみを表示
    const mobileWeeksCount = Math.min(17, totalWeeksCount)
    const startWeekIndex = Math.max(0, totalWeeksCount - mobileWeeksCount)
    
    const mobileWeekdayData = {}
    Object.keys(weekdayData).forEach(wday => {
      mobileWeekdayData[wday] = weekdayData[wday].slice(startWeekIndex)
    })
    
    return {
      weekdayData: mobileWeekdayData,
      weeksCount: mobileWeeksCount
    }
  }

  handleResize() {
    // デバウンス処理で頻繁な再描画を防ぐ
    clearTimeout(this.resizeTimeout)
    this.resizeTimeout = setTimeout(() => {
      this.renderHeatmap()
    }, 250)
  }

  disconnect() {
    // リサイズハンドラーを削除
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
    
    // スタイルは他のヒートマップでも使うので削除しない
  }
}