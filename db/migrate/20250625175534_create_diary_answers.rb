class CreateDiaryAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :diary_answers do |t|
      t.references :diary, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :answer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
