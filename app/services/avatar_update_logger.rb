class AvatarUpdateLogger
  def self.log_success(user_id, provider, url = nil)
    masked_url = url ? mask_url(url) : "[NO_URL]"
    Rails.logger.info "#{provider.capitalize} avatar fetched for user #{user_id}: #{masked_url}"
  end

  def self.log_error(user_id, provider, error)
    Rails.logger.error "Failed to fetch #{provider} avatar for user #{user_id}: #{error.message}"
  end

  def self.mask_url(url)
    return "[INVALID_URL]" unless url.is_a?(String)

    begin
      uri = URI.parse(url)
      "#{uri.scheme}://#{uri.host}/*****"
    rescue URI::InvalidURIError
      "[MALFORMED_URL]"
    end
  end
end
