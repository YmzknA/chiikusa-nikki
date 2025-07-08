class RemoveAvatarUrlFromUsers < ActiveRecord::Migration[7.2]
  def change
    # Removing avatar_url column as we're transitioning to CarrierWave uploader
    # with the 'avatar' column. This migration assumes no production data needs to be preserved.
    remove_column :users, :avatar_url, :string
  end
end
