class CreateDiaries < ActiveRecord::Migration[7.2]
  def change
    create_table :diaries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.text :notes
      t.text :til_text
      t.integer :selected_til_index
      t.boolean :is_public

      t.timestamps
    end
  end
end
