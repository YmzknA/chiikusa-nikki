class AddDefaultToIsPublicInDiaries < ActiveRecord::Migration[7.2]
  def change
    change_column_default :diaries, :is_public, false
    change_column_null :diaries, :is_public, false, false
    add_index :diaries, :is_public
    add_index :diaries, [:is_public, :date]
  end
end