class AddUniqueIndexToDiariesUserIdAndDate < ActiveRecord::Migration[7.2]
  def change
    add_index :diaries, [:user_id, :date], unique: true, name: "index_diaries_on_user_id_and_date"
  end
end
