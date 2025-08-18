import { Controller } from "@hotwired/stimulus"

// MonthFilterController - 月選択フィルターの自動サブミット機能
export default class extends Controller {
  static targets = ["select"]

  change() {
    this.selectTarget.form.submit()
  }
}
