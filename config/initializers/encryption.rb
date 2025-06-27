# Rails Active Record Encryption Configuration
#
# This initializer ensures that encryption is properly configured for all environments.
# The encryption keys should be stored in Rails credentials (config/credentials.yml.enc).
#
# To add encryption keys to credentials, run:
#   EDITOR="code --wait" bin/rails credentials:edit
#
# Add the following to credentials:
#   active_record_encryption:
#     primary_key: <your_primary_key>
#     deterministic_key: <your_deterministic_key>
#     key_derivation_salt: <your_key_derivation_salt>
#
# Generate new keys with: bin/rails db:encryption:init

Rails.application.configure do
  # Validate that encryption is properly configured
  if Rails.application.credentials.active_record_encryption.present?
    Rails.logger.info "Active Record encryption configured successfully."
  else
    Rails.logger.warn "Active Record encryption credentials are missing. GitHub OAuth tokens will not be encrypted."

    # In development, allow graceful degradation
    if Rails.env.development?
      Rails.logger.warn "Running in development mode without encryption. Please add encryption credentials."
    elsif Rails.env.production? && !ENV["SECRET_KEY_BASE_DUMMY"]
      # In production, fail fast to prevent security issues (but allow asset precompilation)
      raise "Active Record encryption credentials are required in production. Please configure credentials.yml.enc."
    end
  end
end
