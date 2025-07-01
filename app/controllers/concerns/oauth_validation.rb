# frozen_string_literal: true

module OauthValidation
  extend ActiveSupport::Concern

  private

  # OAuth認証の有効性を検証（統一実装）
  def valid_oauth_request?(auth)
    return false unless basic_oauth_valid?(auth)
    return false unless valid_email_format?(auth.info.email)

    # プロバイダーが許可されているかチェック
    allowed_providers = %w[github google_oauth2]
    allowed_providers.include?(auth.provider)
  end

  def basic_oauth_valid?(auth)
    auth.present? &&
      auth.provider.present? &&
      auth.uid.present? &&
      auth.info&.email.present?
  end

  def valid_email_format?(email)
    email.match?(/\A[^@\s]+@[^@\s]+\z/)
  end

  # OAuth認証試行のログ記録（統一実装）
  def log_oauth_attempt(provider, email, success)
    status = success ? "SUCCESS" : "FAILURE"
    masked_email = mask_email(email)
    user_info = user_signed_in? ? "user_id=#{current_user.id}" : "anonymous"

    Rails.logger.info(
      "OAuth #{status}: Provider=#{provider}, Email=#{masked_email}, #{user_info}, IP=#{request.remote_ip}"
    )
  rescue StandardError => e
    Rails.logger.warn "Failed to log OAuth attempt: #{e.message}"
  end

  def mask_email(email)
    return "[NO EMAIL]" unless email.present?

    email.gsub(/(.{2}).*@/, '\1***@')
  end
end
