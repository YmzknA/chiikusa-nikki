import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("DiaryView controller connected")
    this.initializeView()
  }

  initializeView() {
    // Check if list tab should be selected based on URL parameters or localStorage
    const urlParams = new URLSearchParams(window.location.search)
    const hasMonthParam = urlParams.has('month')
    const savedView = localStorage.getItem('diary-view')
    
    if (hasMonthParam || savedView === 'list') {
      const listTab = document.getElementById("list-tab")
      if (listTab) {
        listTab.checked = true
        this.showListView()
      }
    }
  }

  showCalendarView() {
    console.log("Switching to calendar view")
    const calendarView = document.getElementById("calendar-view")
    const listView = document.getElementById("list-view")
    const monthFilter = document.getElementById("month-filter")

    // Toggle views
    if (calendarView && listView) {
      calendarView.classList.remove("hidden")
      listView.classList.add("hidden")
    }

    // Hide month filter for calendar view
    if (monthFilter) {
      monthFilter.classList.add("hidden")
      monthFilter.classList.remove("flex")
    }

    // Store view preference
    localStorage.setItem('diary-view', 'calendar')
  }

  showListView() {
    console.log("Switching to list view")
    const calendarView = document.getElementById("calendar-view")
    const listView = document.getElementById("list-view")
    const monthFilter = document.getElementById("month-filter")

    // Toggle views
    if (calendarView && listView) {
      calendarView.classList.add("hidden")
      listView.classList.remove("hidden")
    }

    // Show month filter for list view
    if (monthFilter) {
      monthFilter.classList.remove("hidden")
      monthFilter.classList.add("flex")
    }

    // Store view preference
    localStorage.setItem('diary-view', 'list')
  }

  filterByMonth(event) {
    console.log("Filtering by month")
    const selectElement = event.target
    const form = selectElement.closest('form')
    
    if (form) {
      console.log("Submitting form with selected month:", selectElement.value)
      form.submit()
    } else {
      console.error("Form not found for select element")
    }
  }
}
