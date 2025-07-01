# frozen_string_literal: true

# 環境変数の検証と警告
# アセットプリコンパイル時はデータベース不要のためスキップ
unless ENV["SECRET_KEY_BASE_DUMMY"] == "1" || defined?(Rails::Command::AssetsCommand)
  if Rails.env.production?
    # 本番環境では DATABASE_URL をチェック
    if Rails.application.credentials.dig(:DATABASE_URL).blank?
      Rails.logger.error "Missing required credential: DATABASE_URL"
      raise "Missing required credential: DATABASE_URL"
    end
  elsif Rails.env.development?
    # 開発環境では警告のみ
    optional_vars = %w[DATABASE_HOST DATABASE_USERNAME DATABASE_PASSWORD]
    missing_vars = optional_vars.select { |var| ENV[var].blank? }

    Rails.logger.warn "Using default values for: #{missing_vars.join(', ')}" if missing_vars.any?
  end
end
