class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
  has_many :diary_answers, dependent: :destroy

  validates :identifier, presence: true, uniqueness: true
  validates :label, presence: true

  # 効率的なキャッシュクエリメソッド
  def self.cached_all
    Rails.cache.fetch(cache_key_for(:all), expires_in: CACHE_EXPIRY) do
      Rails.logger.debug "Loading all questions from database" unless Rails.env.production?
      includes(:answers).to_a
    end
  end

  def self.cached_by_identifier
    Rails.cache.fetch(cache_key_for(:by_identifier), expires_in: CACHE_EXPIRY) do
      Rails.logger.debug "Loading questions by identifier from database" unless Rails.env.production?
      includes(:answers).index_by(&:identifier)
    end
  end

  def self.cached_identifiers
    Rails.cache.fetch(cache_key_for(:identifiers), expires_in: CACHE_EXPIRY) do
      Rails.logger.debug "Loading question identifiers from database" unless Rails.env.production?
      pluck(:identifier).map(&:to_sym)
    end
  end

  # キャッシュ設定
  CACHE_EXPIRY = 1.hour
  CACHE_KEYS = %i[all by_identifier identifiers].freeze

  # キャッシュを無効化するコールバック
  after_commit :clear_questions_cache

  private

  def self.cache_key_for(type)
    "questions_#{type}"
  end

  def clear_questions_cache
    CACHE_KEYS.each do |key_type|
      Rails.cache.delete(self.class.cache_key_for(key_type))
    end
    Rails.logger.debug "Cleared questions cache" unless Rails.env.production?
  end
end
