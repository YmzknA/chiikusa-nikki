import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthControls"]
  static values = { chartType: String }

  connect() {
    this.updateMonthControlsVisibility()
    
    // レイアウト自動修正を無効化 - HTMLの初期設定のみに依存
    // this.setupTurboFrameListeners()
    // this.preserveResponsiveLayout()
  }

  updateChart(event) {
    const frameId = this.getFrameId()
    const url = this.buildUpdateUrl(event)
    
    // Turbo Frameによる部分更新
    const frame = document.getElementById(frameId)
    if (frame) {
      frame.src = url
      
      // レスポンシブクラス強制適用を無効化
      // frame.addEventListener('turbo:frame-load', () => {
      //   this.ensureResponsiveClasses()
      // }, { once: true })
    }
    
    // 月選択コントロールの表示更新（日毎推移チャートの場合）
    if (this.chartTypeValue === 'daily-trends' && event.target.name === 'view_type') {
      this.updateMonthControlsVisibility(event.target.value)
    }
  }

  buildUpdateUrl(event) {
    const url = new URL(window.location.pathname, window.location.origin)
    const currentParams = new URLSearchParams(window.location.search)
    
    // チャートタイプに応じてパラメータを設定
    switch (this.chartTypeValue) {
      case 'daily-trends':
        this.setDailyTrendsParams(url, currentParams, event)
        break
      case 'weekday-pattern':
        this.setWeekdayPatternParams(url, currentParams, event)
        break
      case 'distribution':
        this.setDistributionParams(url, currentParams, event)
        break
    }
    
    return url.toString()
  }

  setDailyTrendsParams(url, currentParams, event) {
    if (event.target.name === 'view_type') {
      const viewType = event.target.value
      url.searchParams.set('view_type', viewType)
      
      if (viewType === 'monthly') {
        const monthInput = this.element.querySelector('input[name="target_month"]')
        if (monthInput) {
          url.searchParams.set('target_month', monthInput.value)
        }
      } else {
        url.searchParams.delete('target_month')
      }
    } else if (event.target.name === 'target_month') {
      const viewSelect = this.element.querySelector('select[name="view_type"]')
      url.searchParams.set('view_type', viewSelect.value)
      url.searchParams.set('target_month', event.target.value)
    }
    
    // 他のパラメータを保持
    this.preserveOtherParamsUrl(url, currentParams, ['view_type', 'target_month'])
  }

  setWeekdayPatternParams(url, currentParams, event) {
    url.searchParams.set('weekday_months', event.target.value)
    this.preserveOtherParamsUrl(url, currentParams, ['weekday_months'])
  }

  setDistributionParams(url, currentParams, event) {
    url.searchParams.set('distribution_months', event.target.value)
    this.preserveOtherParamsUrl(url, currentParams, ['distribution_months'])
  }

  preserveOtherParamsUrl(url, currentParams, excludeParams) {
    for (const [key, value] of currentParams) {
      if (!excludeParams.includes(key)) {
        url.searchParams.set(key, value)
      }
    }
  }

  getFrameId() {
    switch (this.chartTypeValue) {
      case 'daily-trends':
        return 'daily-trends-chart'
      case 'weekday-pattern':
        return 'weekday-pattern-chart'
      case 'distribution':
        return 'distribution-chart'
      default:
        return 'stats-content'
    }
  }

  updateMonthControlsVisibility(viewType = null) {
    if (this.chartTypeValue !== 'daily-trends' || !this.hasMonthControlsTarget) return
    
    const currentViewType = viewType || this.element.querySelector('select[name="view_type"]')?.value
    
    if (currentViewType === 'recent') {
      this.monthControlsTarget.className = 'flex items-center gap-2 w-full hidden'
    } else {
      this.monthControlsTarget.className = 'flex items-center gap-2 w-full'
    }
  }

  ensureResponsiveClasses() {
    // 完全に無効化 - HTMLクラスに干渉しない
    return
  }

  setupTurboFrameListeners() {
    // 完全に無効化 - Turbo Frameに干渉しない
    return
  }

  preserveResponsiveLayout() {
    // 完全に無効化 - HTMLクラスに干渉しない
    return
  }

  disconnect() {
  }
}