class EncryptUserAccessTokens < ActiveRecord::Migration[7.2]
  def up
    # Create new encrypted column
    add_column :users, :encrypted_access_token, :text
    
    # Migrate existing tokens to encrypted column using raw SQL to avoid model conflicts
    execute <<~SQL
      UPDATE users 
      SET encrypted_access_token = access_token 
      WHERE access_token IS NOT NULL AND access_token != ''
    SQL
    
    # Remove old unencrypted column
    remove_column :users, :access_token
  end

  def down
    # Create old unencrypted column
    add_column :users, :access_token, :string
    
    # Migrate encrypted tokens back to unencrypted column using raw SQL
    execute <<~SQL
      UPDATE users 
      SET access_token = encrypted_access_token 
      WHERE encrypted_access_token IS NOT NULL AND encrypted_access_token != ''
    SQL
    
    # Remove encrypted column
    remove_column :users, :encrypted_access_token
  end
end