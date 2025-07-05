class AiServiceErrorHandler
  MESSAGES = {
    rate_limit: "現在、AIサービスが混雑しています。しばらく待ってからお試しください。",
    auth_error: "AIサービスの認証エラーが発生しました。管理者にお問い合わせください。",
    timeout: "AIサービスの応答に時間がかかりすぎています。時間をおいて再度お試しください。",
    general: "AIサービスでエラーが発生しました。時間をおいて再度お試しください。"
  }.freeze

  class << self
    def handle_openai_error(error)
      case error.class.name
      when "OpenAI::RateLimitError"
        MESSAGES[:rate_limit]
      when "OpenAI::AuthenticationError"
        MESSAGES[:auth_error]
      when "Net::TimeoutError", "Timeout::Error", "Net::ReadTimeout"
        MESSAGES[:timeout]
      else
        MESSAGES[:general]
      end
    end

    def log_error(error, context = {})
      Rails.logger.error "OpenAI API error: #{error.class} - #{error.message}"
      Rails.logger.debug "Error context: #{context}" unless Rails.env.production?
    end

    def timeout_error?(error)
      %w[Net::TimeoutError Timeout::Error Net::ReadTimeout].include?(error.class.name)
    end
  end
end
