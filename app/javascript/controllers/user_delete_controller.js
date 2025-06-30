import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal", "form", "usernameInput", "confirmUsernameField"]
    static values = { expectedUsername: String }

    connect() {
        console.log("User delete controller connected")
        this.expectedUsernameValue = this.element.dataset.expectedUsername || ""
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
        
        const enteredUsername = this.usernameInputTarget.value.trim()
        const expectedUsername = this.element.dataset.expectedUsername
        
        console.log("Entered username:", enteredUsername)
        console.log("Expected username:", expectedUsername)
        
        if (!enteredUsername) {
            alert("ユーザー名を入力してください。")
            return
        }
        
        if (enteredUsername !== expectedUsername) {
            alert("ユーザー名が正しくありません。")
            this.usernameInputTarget.focus()
            return
        }
        
        console.log("Username validation passed, submitting form")
        
        // 隠しフィールドにユーザー名を設定
        this.confirmUsernameFieldTarget.value = enteredUsername
        
        this.formTarget.submit()
    }

    // ESCキーや背景クリックでのモーダル閉じる処理
    handleModalClose(event) {
        if (event.type === "click" && event.target === this.modalTarget) {
            this.closeModal()
        }
    }
}