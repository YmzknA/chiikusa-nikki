class AddAvatarUpdatedAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :avatar_updated_at, :datetime
  end
end
