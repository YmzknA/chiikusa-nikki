import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["listTab", "calendarView", "listView", "monthFilter"]

  connect() {
    console.log("DiaryView controller connected")
    this.initializeView()
  }

  initializeView() {
    try {
      // Check if list tab should be selected based on URL parameters only
      const urlParams = new URLSearchParams(window.location.search)
      const hasMonthParam = urlParams.has('month')
      
      if (hasMonthParam) {
        if (this.hasListTabTarget) {
          this.listTabTarget.checked = true
          this.showListView()
        }
      }
    } catch (error) {
      console.error("Error initializing view:", error)
      // Fallback to default calendar view
      this.showCalendarView()
    }
  }

  showCalendarView() {
    try {
      console.log("Switching to calendar view")

      // Toggle views
      if (this.hasCalendarViewTarget && this.hasListViewTarget) {
        this.calendarViewTarget.classList.remove("hidden")
        this.listViewTarget.classList.add("hidden")
      }

      // Hide month filter for calendar view
      if (this.hasMonthFilterTarget) {
        this.monthFilterTarget.classList.add("hidden")
        this.monthFilterTarget.classList.remove("flex")
      }
    } catch (error) {
      console.error("Error switching to calendar view:", error)
    }
  }

  showListView() {
    try {
      console.log("Switching to list view")

      // Toggle views
      if (this.hasCalendarViewTarget && this.hasListViewTarget) {
        this.calendarViewTarget.classList.add("hidden")
        this.listViewTarget.classList.remove("hidden")
      }

      // Show month filter for list view
      if (this.hasMonthFilterTarget) {
        this.monthFilterTarget.classList.remove("hidden")
        this.monthFilterTarget.classList.add("flex")
      }
    } catch (error) {
      console.error("Error switching to list view:", error)
    }
  }

  filterByMonth(event) {
    try {
      console.log("Filtering by month")
      const selectElement = event.target
      const form = selectElement.closest('form')
      
      if (form) {
        console.log("Submitting form with selected month:", selectElement.value)
        form.submit()
      } else {
        console.error("Form not found for select element")
      }
    } catch (error) {
      console.error("Error filtering by month:", error)
    }
  }
}
