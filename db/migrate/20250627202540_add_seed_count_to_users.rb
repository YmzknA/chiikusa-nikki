class AddSeedCountToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :seed_count, :integer, default: 0, null: false
    add_column :users, :last_seed_incremented_at, :datetime
    add_column :users, :last_shared_at, :datetime
  end
end
