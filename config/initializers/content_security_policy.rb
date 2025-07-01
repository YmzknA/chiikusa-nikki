# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # デフォルトのソース制限
    policy.default_src :self
    
    # フォント（Google Fontsとローカルフォント）
    policy.font_src :self, :data, 'https://fonts.gstatic.com'
    
    # 画像（self、data URI、HTTPSすべて許可）
    policy.img_src :self, :data, :https
    
    # オブジェクト（Flash等）は完全にブロック
    policy.object_src :none
    
    # スクリプト（self、nonceベースのインラインスクリプト、Google APIs）
    # TODO: unsafe-inlineは段階的に削除し、すべてStimulusコントローラーに移行する
    policy.script_src :self, 
                      :unsafe_inline,  # 一時的に許可（将来削除予定）
                      'https://apis.google.com'
    
    # スタイルシート（self、インライン、Google Fonts）
    policy.style_src :self, 
                     :unsafe_inline,  # Tailwind CSSとStimulus用
                     'https://fonts.googleapis.com'
    
    # API接続先（self、GitHub API、OpenAI API、Google OAuth）
    policy.connect_src :self,
                       'https://api.github.com',
                       'https://api.openai.com',
                       'https://apis.google.com',
                       'https://accounts.google.com',
                       'wss:'  # Action Cable WebSocket用
    
    # フォーム送信先（self、GitHub OAuth、Google OAuth）
    policy.form_action :self,
                       'https://github.com',
                       'https://accounts.google.com'
    
    # frame-ancestors（クリックジャッキング防止）
    policy.frame_ancestors :none
    
    # 子フレーム（iframe）のソース
    policy.frame_src :none
    
    # メディアソース（音声・動画）
    policy.media_src :none
    
    # Workerスクリプト（Service Worker用）
    policy.worker_src :self
    
    # マニフェスト（PWA用）
    policy.manifest_src :self
    
    # ベースURI（相対URLの基準）
    policy.base_uri :self
    
    # CSP違反レポートの送信先
    policy.report_uri "/csp-violation-report"
  end

  # インラインスクリプト用のnonce生成（将来的に使用予定）
  # config.content_security_policy_nonce_generator = ->(request) { 
  #   SecureRandom.base64(16)
  # }
  # config.content_security_policy_nonce_directives = %w[script-src]

  # 開発環境では違反をレポートのみ（本番環境では強制）
  config.content_security_policy_report_only = Rails.env.development?
  
  # 本番環境でのみ、より厳格なセキュリティポリシーを適用
  # if Rails.env.production?
  #   # 追加の本番環境設定はここに記載
  # end
end
