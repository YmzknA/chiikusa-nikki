class CreateReactions < ActiveRecord::Migration[7.2]
  def change
    create_table :reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :diary, null: false, foreign_key: true
      t.string :emoji, null: false

      t.timestamps
    end

    add_index :reactions, [:user_id, :diary_id, :emoji], unique: true
    add_index :reactions, [:diary_id, :emoji]
  end
end
