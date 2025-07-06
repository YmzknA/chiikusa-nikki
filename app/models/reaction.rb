class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :diary

  # 絵文字カテゴリの定数定義
  EMOJI_CATEGORIES = {
    emotion: { label: "感情系", emojis: ["😂", "😎", "😘", "🥲", "😭"] },
    support: { label: "応援系", emojis: ["🫰", "🤝", "🌱", "🔥", "✨"] },
    learning: { label: "学習系", emojis: ["📚", "💡", "🎯", "✅", "🚀"] },
    reaction: { label: "反応系", emojis: ["😲", "🤔", "💕", "👀", "💯"] }
  }.freeze

  # 全ての利用可能な絵文字リスト
  ALL_EMOJIS = EMOJI_CATEGORIES.values.flat_map { |category| category[:emojis] }.freeze

  validates :emoji, presence: true, inclusion: { in: ALL_EMOJIS }
  validates :user_id, uniqueness: { scope: [:diary_id, :emoji], message: "は既に同じ絵文字でリアクションしています" }

  scope :by_emoji, ->(emoji) { where(emoji: emoji) }
  scope :by_diary, ->(diary) { where(diary: diary) }
  scope :by_user, ->(user) { where(user: user) }

  def self.emoji_category(emoji)
    EMOJI_CATEGORIES.find { |_key, category| category[:emojis].include?(emoji) }&.first
  end

  def category
    self.class.emoji_category(emoji)
  end
end
