class Diary < ApplicationRecord
  belongs_to :user
  has_many :diary_answers, dependent: :destroy
  has_many :til_candidates, dependent: :destroy
  has_many :reactions, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :user_id, message: "の日記は既に作成されています" }

  scope :public_diaries, -> { where(is_public: true) }
  scope :private_diaries, -> { where(is_public: false) }
  scope :calendar_range, lambda { |start_date, end_date|
    includes(diary_answers: :answer)
      .where(date: start_date..end_date)
      .order(date: :desc)
  }

  # 統計チャートのキャッシュを無効化
  after_commit :clear_stats_cache

  def github_uploaded?
    github_uploaded == true
  end

  def can_upload_to_github?
    !github_uploaded? && user.github_repo_name.present?
  end

  def github_file_path
    "#{date.strftime('%Y/%m')}/#{date.strftime('%y%m%d')}_til.md"
  end

  def selected_til_content
    return nil unless selected_til_index.present?

    til_candidates.find_by(index: selected_til_index)&.content
  end

  def reactions_summary(preloaded_data = nil)
    # メモ化でキャッシュ、またはコントローラーからの事前計算データを使用
    # preloaded_dataはハッシュで、キーが絵文字、値がカウントの形
    # 例: { "😂" => 5, "😎" => 3, ... }
    @reactions_summary ||= preloaded_data || generate_reactions_summary
  end

  def user_reactions(user)
    return [] unless user

    reactions.where(user: user).pluck(:emoji)
  end

  def user_reacted?(user, emoji, preloaded_user_reactions = nil)
    return false unless user

    # コントローラーから事前計算されたユーザーリアクションデータを使用
    return preloaded_user_reactions.include?(emoji) if preloaded_user_reactions

    # メモ化でキャッシュしてクエリ削減
    cached_user_reactions(user).include?(emoji)
  end

  private

  def generate_reactions_summary
    summary = build_reactions_count
    sort_reactions_by_emoji_order(summary)
  end

  # ["😂" => 5, "😎" => 3, ... ]の形が返る
  def build_reactions_count
    if reactions.loaded?
      reactions.group_by(&:emoji).transform_values(&:size)
    else
      reactions.group(:emoji).count
    end
  end

  def sort_reactions_by_emoji_order(summary)
    emoji_order = Reaction::EMOJI_CATEGORIES.values.flat_map { |category| category[:emojis] }
    summary.sort_by { |emoji, _count| emoji_order.index(emoji) || Float::INFINITY }.to_h
  end

  def cached_user_reactions(user)
    @user_reactions_cache ||= {}
    @user_reactions_cache[user.id] ||= if reactions.loaded?
                                         reactions.select { |r| r.user_id == user.id }.map(&:emoji)
                                       else
                                         reactions.where(user: user).pluck(:emoji)
                                       end
    @user_reactions_cache[user.id]
  end

  def clear_stats_cache
    # ハッシュ化されたuser_idを使用してキャッシュクリア
    user_hash = Digest::SHA256.hexdigest(user_id.to_s)[0, 8]
    Rails.cache.delete_matched("stats_charts_#{user_hash}_*")
  end
end
