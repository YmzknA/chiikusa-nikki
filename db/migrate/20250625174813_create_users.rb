class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :github_id
      t.string :username
      t.string :access_token

      t.timestamps
    end
    add_index :users, :github_id, unique: true
  end
end
