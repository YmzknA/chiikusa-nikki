class CspReportsController < ApplicationController
  # CSP違反レポートエンドポイント
  # CSRFトークンチェックをスキップ（ブラウザからの自動送信のため）
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def create
    # CSP違反レポートをログに記録
    if params['csp-report'].present?
      violation = params['csp-report']
      
      Rails.logger.warn "CSP Violation Detected:"
      Rails.logger.warn "  Document URI: #{violation['document-uri']}"
      Rails.logger.warn "  Blocked URI: #{violation['blocked-uri']}"
      Rails.logger.warn "  Violated Directive: #{violation['violated-directive']}"
      Rails.logger.warn "  Original Policy: #{violation['original-policy']}"
      Rails.logger.warn "  Source File: #{violation['source-file']}"
      Rails.logger.warn "  Line Number: #{violation['line-number']}"
      
      # 本番環境では、監視サービスにも送信することを推奨
      # Sentry.capture_message("CSP Violation", extra: violation) if defined?(Sentry)
    end
    
    head :no_content
  end
end