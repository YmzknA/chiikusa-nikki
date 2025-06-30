import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal", "form"]

    connect() {
        console.log("User delete controller connected")
    }

    // モーダルを開く
    openModal(event) {
        event.preventDefault()
        console.log("Opening delete confirmation modal")
        this.modalTarget.showModal()
    }

    // モーダルを閉じる
    closeModal() {
        console.log("Closing delete confirmation modal")
        this.modalTarget.close()
    }

    // 削除を実行
    confirmDelete() {
        console.log("Confirming user deletion")
        this.formTarget.submit()
    }

    // ESCキーや背景クリックでのモーダル閉じる処理
    handleModalClose(event) {
        if (event.type === "click" && event.target === this.modalTarget) {
            this.closeModal()
        }
    }
}