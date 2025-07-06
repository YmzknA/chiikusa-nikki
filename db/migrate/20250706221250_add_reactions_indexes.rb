class AddReactionsIndexes < ActiveRecord::Migration[7.0]
  def change
    # リアクション検索・集計のパフォーマンス最適化用インデックス
    
    # 日記別の絵文字集計用（reactions_summary メソッド）
    # 既存のマイグレーションで作成済みのため削除
    
    # ユーザー別のリアクション検索用（user_reacted? メソッド）
    add_index :reactions, [:user_id, :diary_id], name: 'index_reactions_on_user_diary'
    
    # 重複リアクション防止の複合ユニーク制約強化
    # 既存のバリデーションに加え、データベースレベルでも制約を追加
    add_index :reactions, [:diary_id, :user_id, :emoji], 
              unique: true, 
              name: 'index_reactions_unique_constraint'
  end
end