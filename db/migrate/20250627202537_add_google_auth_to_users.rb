class AddGoogleAuthToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :google_id, :string
    add_index :users, :google_id
    add_column :users, :google_email, :string
    add_index :users, :google_email
    add_column :users, :encrypted_google_access_token, :string
    add_column :users, :providers, :text
  end
end
