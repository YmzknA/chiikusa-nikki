class CreateAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :answers do |t|
      t.references :question, null: false, foreign_key: true
      t.integer :level
      t.string :label
      t.string :emoji

      t.timestamps
    end
  end
end
