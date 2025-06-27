class EncryptUserAccessTokens < ActiveRecord::Migration[7.2]
  def up
    # Create new encrypted column
    add_column :users, :encrypted_access_token, :text
    
    # Migrate existing tokens to encrypted column
    User.find_each do |user|
      if user.access_token.present?
        user.update_columns(encrypted_access_token: user.access_token)
      end
    end
    
    # Remove old unencrypted column
    remove_column :users, :access_token
  end

  def down
    # Create old unencrypted column
    add_column :users, :access_token, :string
    
    # Migrate encrypted tokens back to unencrypted column
    User.find_each do |user|
      if user.encrypted_access_token.present?
        user.update_columns(access_token: user.encrypted_access_token)
      end
    end
    
    # Remove encrypted column
    remove_column :users, :encrypted_access_token
  end
end