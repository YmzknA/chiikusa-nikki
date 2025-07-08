class AvatarUpdateLogger
  def self.log_success(user_id, provider, url_hint = "[MASKED]")
    Rails.logger.info "#{provider.capitalize} avatar fetched for user #{user_id}: #{url_hint}"
  end

  def self.log_error(user_id, provider, error)
    Rails.logger.error "Failed to fetch #{provider} avatar for user #{user_id}: #{error.message}"
  end
end
