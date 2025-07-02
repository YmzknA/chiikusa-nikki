import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Object,
    options: Object
  }

  connect() {
    this.renderCalendar()
  }

  renderCalendar() {
    if (!this.dataValue || !this.dataValue.weeks) {
      console.error("Calendar data is missing or invalid", this.dataValue)
      this.element.innerHTML = '<div class="p-4 text-center text-red-500">カレンダーデータの読み込みに失敗しました</div>'
      return
    }

    const weeks = this.dataValue.weeks
    const weekdays = this.dataValue.weekdays
    const month = this.dataValue.month
    
    
    // カレンダーのHTMLを生成
    let calendarHTML = `
      <div class="calendar-container">
        <div class="calendar-header mb-4">
          <h3 class="text-lg font-semibold text-center">${month}</h3>
        </div>
        <div class="calendar-grid">
          <div class="calendar-weekdays">
            ${weekdays.map(day => `<div class="weekday-header">${day}</div>`).join('')}
          </div>
          ${weeks.map(week => this.renderWeek(week)).join('')}
        </div>
        <div class="calendar-legend mt-4">
          <div class="flex flex-wrap items-center justify-center gap-4 text-sm text-base-content/70">
            <div class="flex items-center gap-2">
              <div class="legend-dot bg-success"></div>
              <span>記録あり</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="legend-dot bg-base-300"></div>
              <span>記録なし</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="legend-dot bg-primary ring-2 ring-primary ring-offset-2"></div>
              <span>今日</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="relative">
                <div class="legend-dot bg-success"></div>
                <div class="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-1 h-3 bg-gradient-to-t from-green-500 to-blue-500 rounded-sm"></div>
              </div>
              <span>学習強度</span>
            </div>
          </div>
        </div>
      </div>
    `
    
    this.element.innerHTML = calendarHTML
    this.addStyles()
  }

  renderWeek(week) {
    return `
      <div class="calendar-week">
        ${week.map(day => this.renderDay(day)).join('')}
      </div>
    `
  }

  renderDay(day) {
    const classes = this.getDayClasses(day)
    const intensity = day.intensity || 0
    const intensityText = intensity > 0 ? ` (強度: ${intensity})` : ''
    
    return `
      <div class="${classes}" 
           title="${day.date}${day.has_record ? ' - 記録あり' + intensityText : ' - 記録なし'}"
           data-date="${day.date}"
           data-has-record="${day.has_record}"
           data-intensity="${day.intensity}">
        <span class="day-number">${day.day}</span>
        ${day.has_record ? `
          <div class="record-indicator"></div>
          <div class="intensity-bar" style="height: ${Math.max(2, intensity * 8)}px"></div>
        ` : ''}
      </div>
    `
  }

  getDayClasses(day) {
    let classes = 'calendar-day'
    
    if (!day.is_current_month) {
      classes += ' other-month'
    }
    
    if (day.is_today) {
      classes += ' today'
    }
    
    if (day.has_record) {
      classes += ' has-record'
      // 強度に応じた色分け
      const intensity = day.intensity || 0
      if (intensity >= 3) classes += ' high-intensity'
      else if (intensity >= 2) classes += ' medium-intensity'
      else classes += ' low-intensity'
    }
    
    return classes
  }

  addStyles() {
    if (document.getElementById('calendar-styles')) return
    
    const styles = `
      <style id="calendar-styles">
        .calendar-container {
          max-width: 400px;
          margin: 0 auto;
        }
        .calendar-grid {
          border-radius: 8px;
          overflow: hidden;
          border: 1px solid oklch(var(--b3));
        }
        .calendar-weekdays {
          display: grid;
          grid-template-columns: repeat(7, 1fr);
          background: oklch(var(--b2));
        }
        .weekday-header {
          padding: 8px 4px;
          text-align: center;
          font-size: 12px;
          font-weight: 600;
          color: oklch(var(--bc) / 0.7);
          border-right: 1px solid oklch(var(--b3));
        }
        .weekday-header:last-child {
          border-right: none;
        }
        .calendar-week {
          display: grid;
          grid-template-columns: repeat(7, 1fr);
          border-bottom: 1px solid oklch(var(--b3));
        }
        .calendar-week:last-child {
          border-bottom: none;
        }
        .calendar-day {
          position: relative;
          aspect-ratio: 1;
          display: flex;
          align-items: center;
          justify-content: center;
          border-right: 1px solid oklch(var(--b3));
          background: oklch(var(--b1));
          cursor: pointer;
          transition: all 0.2s;
          min-height: 40px;
        }
        .calendar-day:last-child {
          border-right: none;
        }
        .calendar-day:hover {
          background: oklch(var(--b2));
        }
        .calendar-day.other-month {
          background: oklch(var(--b2));
          opacity: 0.4;
        }
        .calendar-day.today {
          background: oklch(var(--p));
          color: oklch(var(--pc));
          font-weight: bold;
        }
        .calendar-day.has-record {
          background: oklch(var(--su));
          color: oklch(var(--suc));
        }
        .calendar-day.has-record.medium-intensity {
          background: oklch(var(--su) / 0.8);
        }
        .calendar-day.has-record.high-intensity {
          background: oklch(var(--su) / 0.9);
          box-shadow: 0 0 0 2px oklch(var(--su));
        }
        .calendar-day.today.has-record {
          background: oklch(var(--p));
          box-shadow: 0 0 0 3px oklch(var(--su));
        }
        .day-number {
          font-size: 14px;
          z-index: 1;
        }
        .record-indicator {
          position: absolute;
          top: 2px;
          right: 2px;
          width: 6px;
          height: 6px;
          background: oklch(var(--suc));
          border-radius: 50%;
        }
        .calendar-day.today .record-indicator {
          background: oklch(var(--pc));
        }
        .intensity-bar {
          position: absolute;
          bottom: 2px;
          left: 50%;
          transform: translateX(-50%);
          width: 3px;
          background: linear-gradient(to top, oklch(var(--su)), oklch(var(--p)));
          border-radius: 1px;
          min-height: 2px;
          max-height: 20px;
        }
        .calendar-day.today .intensity-bar {
          background: linear-gradient(to top, oklch(var(--pc)), oklch(var(--p)));
        }
        .legend-dot {
          width: 12px;
          height: 12px;
          border-radius: 50%;
        }
      </style>
    `
    document.head.insertAdjacentHTML('beforeend', styles)
  }

  disconnect() {
    // スタイルは他のカレンダーでも使うので削除しない
  }
}
