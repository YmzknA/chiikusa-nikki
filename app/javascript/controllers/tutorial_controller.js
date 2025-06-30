import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = []

    connect() {
        console.log("Tutorial controller connected")
    }

    close() {
        console.log("Tutorial modal closing")
        // モーダルを閉じる処理
        const modal = this.element.closest('.tutorial-modal')
        if (modal) {
            modal.remove()
        } else {
            // 通常のページからの場合は前のページに戻る
            if (window.history.length > 1) {
                window.history.back()
            } else {
                // 直接アクセスの場合は日記一覧に遷移
                window.location.href = '/diaries'
            }
        }
    }

    // モーダル版のチュートリアルを表示
    showModal() {
        console.log("Showing tutorial modal")
        
        // セキュアなDOM要素作成
        const modalDiv = document.createElement('div')
        modalDiv.className = 'tutorial-modal fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50'
        modalDiv.setAttribute('data-controller', 'tutorial')
        
        const contentDiv = document.createElement('div')
        contentDiv.className = 'min-h-screen px-4 text-center'
        
        const overlayDiv = document.createElement('div')
        overlayDiv.className = 'fixed inset-0'
        overlayDiv.setAttribute('data-action', 'click->tutorial#close')
        
        const modalContent = document.createElement('div')
        modalContent.className = 'inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full'
        
        const modalBody = document.createElement('div')
        modalBody.className = 'bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4'
        
        const header = document.createElement('div')
        header.className = 'flex justify-between items-center mb-4'
        
        const title = document.createElement('h3')
        title.className = 'text-lg leading-6 font-medium text-gray-900'
        title.textContent = '🌱 ちいくさ日記の使い方'
        
        const closeButton = document.createElement('button')
        closeButton.className = 'text-gray-400 hover:text-gray-600'
        closeButton.setAttribute('data-action', 'click->tutorial#close')
        closeButton.innerHTML = '<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>'
        
        const contentArea = document.createElement('div')
        contentArea.className = 'max-h-96 overflow-y-auto'
        contentArea.innerHTML = this.getModalContent()
        
        const footer = document.createElement('div')
        footer.className = 'bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse'
        
        const startButton = document.createElement('button')
        startButton.className = 'w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-green-600 text-base font-medium text-white hover:bg-green-700 focus:outline-none sm:ml-3 sm:w-auto sm:text-sm'
        startButton.setAttribute('data-action', 'click->tutorial#close')
        startButton.textContent = '始める'
        
        // DOM構造を組み立て
        header.appendChild(title)
        header.appendChild(closeButton)
        footer.appendChild(startButton)
        modalBody.appendChild(header)
        modalBody.appendChild(contentArea)
        modalContent.appendChild(modalBody)
        modalContent.appendChild(footer)
        contentDiv.appendChild(overlayDiv)
        contentDiv.appendChild(modalContent)
        modalDiv.appendChild(contentDiv)
        
        // モーダルをbodyに追加
        document.body.appendChild(modalDiv)
    }

    getModalContent() {
        return `
            <div class="space-y-4">
                <div class="text-center mb-6">
                    <h2 class="text-2xl font-bold text-green-800 mb-2">プログラミング学習を雑草と一緒に記録しよう！</h2>
                </div>
                
                <div class="space-y-4">
                    <div class="border-l-4 border-green-500 pl-4">
                        <h3 class="font-semibold text-green-800 mb-2">📝 日記の作り方</h3>
                        <p class="text-sm text-gray-600">3つの評価（気分・モチベーション・進捗）と学習メモで、あなたの学習を記録します。</p>
                    </div>
                    
                    <div class="border-l-4 border-blue-500 pl-4">
                        <h3 class="font-semibold text-blue-800 mb-2">🤖 AIでTIL生成</h3>
                        <p class="text-sm text-gray-600">学習メモからAIが自動でTIL（Today I Learned）を3つ生成。タネシステムで制限があります。</p>
                    </div>
                    
                    <div class="border-l-4 border-purple-500 pl-4">
                        <h3 class="font-semibold text-purple-800 mb-2">🐙 GitHub連携</h3>
                        <p class="text-sm text-gray-600">GitHubリポジトリに学習記録をアップロードして、継続的な学習で草を生やしましょう。</p>
                    </div>
                    
                    <div class="border-l-4 border-orange-500 pl-4">
                        <h3 class="font-semibold text-orange-800 mb-2">📊 学習の振り返り</h3>
                        <p class="text-sm text-gray-600">統計機能で学習の傾向を分析。グラフで可視化された情報から効率的な学習計画を。</p>
                    </div>
                    
                    <div class="border-l-4 border-pink-500 pl-4">
                        <h3 class="font-semibold text-pink-800 mb-2">👥 コミュニティ</h3>
                        <p class="text-sm text-gray-600">公開日記一覧で他のユーザーの学習記録を見て、モチベーションを高めましょう。</p>
                    </div>
                </div>
                
                <div class="bg-yellow-50 p-4 rounded-lg mt-4">
                    <h3 class="font-semibold text-yellow-800 mb-2">🌱 タネについて</h3>
                    <p class="text-sm text-gray-700">AI生成には「タネ」が必要です：</p>
                    <ul class="text-sm text-gray-700 mt-1 space-y-1">
                        <li>• 毎日の水やりボタン（1日1回）</li>
                        <li>• X（Twitter）での共有（1日1回）</li>
                        <li>• 最大5個まで保持可能</li>
                    </ul>
                </div>
            </div>
        `
    }
}