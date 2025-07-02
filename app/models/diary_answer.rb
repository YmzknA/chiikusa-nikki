class DiaryAnswer < ApplicationRecord
  belongs_to :diary
  belongs_to :question
  belongs_to :answer

  # 統計チャートのキャッシュを無効化
  after_commit :clear_stats_cache

  private

  def clear_stats_cache
    Rails.cache.delete_matched("stats_charts_#{diary.user_id}_*")
  end
end
