class DiaryAnswer < ApplicationRecord
  belongs_to :diary
  belongs_to :question
  belongs_to :answer

  # 統計チャートのキャッシュを無効化
  after_commit :clear_stats_cache, on: [:create, :update, :destroy]

  private

  def clear_stats_cache
    hashed_user_id = Digest::SHA256.hexdigest(diary.user_id.to_s)[0, 8]
    Rails.cache.delete_matched("stats_charts_#{hashed_user_id}_*")
  end
end
