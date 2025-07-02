class RemoveRememberTokenFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :remember_token, :string
  end
end
