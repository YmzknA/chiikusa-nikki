# frozen_string_literal: true

# 環境変数の検証と警告
if Rails.env.production?
  # 本番環境では必須の環境変数をチェック
  required_vars = %w[DATABASE_HOST DATABASE_USERNAME DATABASE_PASSWORD]
  missing_vars = required_vars.select { |var| ENV[var].blank? }

  if missing_vars.any?
    Rails.logger.error "Missing required environment variables: #{missing_vars.join(', ')}"
    raise "Missing required environment variables: #{missing_vars.join(', ')}"
  end
elsif Rails.env.development?
  # 開発環境では警告のみ
  optional_vars = %w[DATABASE_HOST DATABASE_USERNAME DATABASE_PASSWORD]
  missing_vars = optional_vars.select { |var| ENV[var].blank? }

  Rails.logger.warn "Using default values for: #{missing_vars.join(', ')}" if missing_vars.any?
end
