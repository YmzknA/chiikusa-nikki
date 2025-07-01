class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :privacy_policy, :terms_of_service]
  before_action :set_cache_headers, only: [:privacy_policy, :terms_of_service]

  def index; end

  def privacy_policy; end

  def terms_of_service; end

  private

  def set_cache_headers
    # 法的文書のキャッシュ制御（個人開発レベルの基本設定）
    response.headers["Cache-Control"] = "public, max-age=3600" # 1時間
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
  end
end
