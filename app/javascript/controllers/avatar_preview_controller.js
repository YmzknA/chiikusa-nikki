import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "previewContainer"]

  connect() {
    if (process.env.NODE_ENV !== "production") {
      console.log("Avatar preview controller connected")
    }
  }

  showPreview(event) {
    const file = event.target.files[0]
    
    if (file) {
      // ファイルサイズ制限チェック (5MB)
      const maxSize = 5 * 1024 * 1024
      if (file.size > maxSize) {
        alert("ファイルサイズが大きすぎます。5MB以下のファイルを選択してください。")
        event.target.value = ""
        this.hidePreview()
        return
      }

      // ファイルタイプチェック
      const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/webp"]
      if (!allowedTypes.includes(file.type)) {
        alert("対応していないファイル形式です。JPG、PNG、またはWEBP形式のファイルを選択してください。")
        event.target.value = ""
        this.hidePreview()
        return
      }

      // プレビュー表示
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewTarget.src = e.target.result
        this.previewContainerTarget.classList.remove("hidden")
      }
      reader.readAsDataURL(file)
    } else {
      this.hidePreview()
    }
  }

  hidePreview() {
    this.previewContainerTarget.classList.add("hidden")
    this.previewTarget.src = ""
  }
}
