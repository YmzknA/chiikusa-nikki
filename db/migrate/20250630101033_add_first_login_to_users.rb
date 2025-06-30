class AddFirstLoginToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :first_login, :boolean, default: true, null: false
  end
end
