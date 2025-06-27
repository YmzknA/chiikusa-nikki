class InitializeProviderArraysForExistingUsers < ActiveRecord::Migration[7.2]
  def up
    # 既存のユーザーの providers 配列を初期化
    User.where(providers: nil).find_each do |user|
      providers = []
      providers << 'github' if user.github_id.present?
      providers << 'google_oauth2' if user.google_id.present?
      user.update_columns(providers: providers)
    end
  end

  def down
    # ロールバック時は providers をnullに戻す
    User.update_all(providers: nil)
  end
end
