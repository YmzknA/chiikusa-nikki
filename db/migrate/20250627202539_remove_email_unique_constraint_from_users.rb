class RemoveEmailUniqueConstraintFromUsers < ActiveRecord::Migration[7.2]
  def up
    # 既存の一意性インデックスを削除
    remove_index :users, :email, if_exists: true
    # 非一意性インデックスを追加（パフォーマンス維持のため）
    add_index :users, :email, if_not_exists: true
  end

  def down
    # ロールバック時は一意性制約を復元
    remove_index :users, :email, if_exists: true
    add_index :users, :email, unique: true, if_not_exists: true
  end
end
