class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :diary_answers, dependent: :destroy

  validates :identifier, presence: true, uniqueness: true
  validates :label, presence: true

  # キャッシュされたクエリメソッド
  def self.cached_all
    Rails.cache.fetch("questions_all", expires_in: 1.hour) do
      Rails.logger.info("Cache MISS for questions_all")
      all.to_a
    end.tap { Rails.logger.info("Cache HIT for questions_all") if Rails.cache.exist?("questions_all") }
  end

  def self.cached_by_identifier
    Rails.cache.fetch("questions_by_identifier", expires_in: 1.hour) do
      Rails.logger.info("Cache MISS for questions_by_identifier")
      all.index_by(&:identifier)
    end.tap do
      Rails.logger.info("Cache HIT for questions_by_identifier") if Rails.cache.exist?("questions_by_identifier")
    end
  end

  def self.cached_identifiers
    Rails.cache.fetch("question_identifiers", expires_in: 1.hour) do
      Rails.logger.info("Cache MISS for question_identifiers")
      pluck(:identifier).map(&:to_sym)
    end.tap { Rails.logger.info("Cache HIT for question_identifiers") if Rails.cache.exist?("question_identifiers") }
  end

  # キャッシュを無効化するコールバック
  after_commit :clear_questions_cache

  private

  def clear_questions_cache
    Rails.cache.delete("questions_all")
    Rails.cache.delete("questions_by_identifier")
    Rails.cache.delete("question_identifiers")
  end
end
