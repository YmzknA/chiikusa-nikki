class CreateTilCandidates < ActiveRecord::Migration[7.2]
  def change
    create_table :til_candidates do |t|
      t.references :diary, null: false, foreign_key: true
      t.text :content
      t.integer :index

      t.timestamps
    end
  end
end
