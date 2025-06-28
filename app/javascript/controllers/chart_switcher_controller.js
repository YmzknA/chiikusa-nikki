import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chartContainer", "viewSelect", "monthSelect", "monthControls"]
  static values = { 
    chartUrl: String,
    currentViewType: String,
    currentMonth: String
  }

  connect() {
    console.log("Chart switcher controller connected")
    this.updateMonthControlsVisibility()
  }

  switchView() {
    const viewType = this.viewSelectTarget.value
    console.log("Switching view to:", viewType)
    
    this.currentViewTypeValue = viewType
    this.updateMonthControlsVisibility()
    this.loadChartData()
  }

  changeMonth() {
    const month = this.monthSelectTarget.value
    console.log("Changing month to:", month)
    
    this.currentMonthValue = month
    this.loadChartData()
  }

  previousMonth() {
    const currentDate = new Date(this.currentMonthValue + "-01")
    currentDate.setMonth(currentDate.getMonth() - 1)
    const newMonth = this.formatMonth(currentDate)
    
    this.currentMonthValue = newMonth
    this.monthSelectTarget.value = newMonth
    this.loadChartData()
  }

  nextMonth() {
    const currentDate = new Date(this.currentMonthValue + "-01")
    currentDate.setMonth(currentDate.getMonth() + 1)
    const newMonth = this.formatMonth(currentDate)
    
    this.currentMonthValue = newMonth
    this.monthSelectTarget.value = newMonth
    this.loadChartData()
  }

  loadChartData() {
    const url = new URL(this.chartUrlValue, window.location.origin)
    url.searchParams.set('view_type', this.currentViewTypeValue)
    
    if (this.currentViewTypeValue === 'monthly') {
      url.searchParams.set('target_month', this.currentMonthValue)
    }
    
    console.log("Loading chart data from:", url.toString())
    
    fetch(url)
      .then(response => response.json())
      .then(data => {
        console.log("Chart data received:", data)
        this.updateChart(data)
      })
      .catch(error => {
        console.error("Error loading chart data:", error)
      })
  }

  updateChart(chartData) {
    // 既存のチャートコントローラーを探す
    const chartElement = this.chartContainerTarget.querySelector('[data-controller*="chart"]')
    if (!chartElement) {
      console.error("Chart element not found")
      return
    }

    // チャートコントローラーのインスタンスを取得
    const chartController = this.application.getControllerForElementAndIdentifier(chartElement, "chart")
    if (!chartController) {
      console.error("Chart controller not found")
      return
    }

    // 既存のチャートを破棄
    if (chartController.chart) {
      chartController.chart.destroy()
    }

    // 新しいデータでチャートを再作成
    chartController.typeValue = chartData.type
    chartController.dataValue = chartData.data
    chartController.optionsValue = chartData.options
    
    // チャートを再接続
    chartController.connect()
  }

  updateMonthControlsVisibility() {
    if (this.currentViewTypeValue === 'monthly') {
      this.monthControlsTarget.classList.remove('hidden')
    } else {
      this.monthControlsTarget.classList.add('hidden')
    }
  }

  formatMonth(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    return `${year}-${month}`
  }
}