class AddGoogleAvatarUrlToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :google_avatar_url, :string
  end
end
