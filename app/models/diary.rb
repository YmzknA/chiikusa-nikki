class Diary < ApplicationRecord
  belongs_to :user
  has_many :diary_answers, dependent: :destroy
  has_many :til_candidates, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :user_id, message: "の日記は既に作成されています" }

  scope :public_diaries, -> { where(is_public: true) }
  scope :private_diaries, -> { where(is_public: false) }

  # 統計チャートのキャッシュを無効化
  after_commit :clear_stats_cache

  def github_uploaded?
    github_uploaded == true
  end

  def can_upload_to_github?
    !github_uploaded? && user.github_repo_name.present?
  end

  def selected_til_content
    return nil unless selected_til_index.present?

    til_candidates.find_by(index: selected_til_index)&.content
  end

  private

  def clear_stats_cache
    Rails.cache.delete_matched("stats_charts_#{user_id}_*")
  end
end
