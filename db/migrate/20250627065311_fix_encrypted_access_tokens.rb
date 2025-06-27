class FixEncryptedAccessTokens < ActiveRecord::Migration[7.2]
  def up
    # Clear all existing encrypted_access_token values that were improperly migrated
    # Users will need to re-authenticate to get new encrypted tokens
    execute <<~SQL
      UPDATE users 
      SET encrypted_access_token = NULL 
      WHERE encrypted_access_token IS NOT NULL
    SQL
    
    Rails.logger.info "Cleared invalid encrypted access tokens. Users will need to re-authenticate."
  end

  def down
    # No rollback needed - tokens were already invalid
  end
end