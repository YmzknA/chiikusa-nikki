class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.string :identifier
      t.string :label
      t.string :icon

      t.timestamps
    end
  end
end
