# SeedServiceは種（AI生成回数制限）の管理を行うサービスクラス
class SeedService
  attr_reader :user, :success, :message

  def initialize(user)
    @user = user
  end

  # 🌱ボタンクリックで種を増加
  def increment_daily_seed
    @success = user.increment_seed_count
    @message = success ? "種を増やしました！💧🌱" : "本日は既に種を増やしています。"
    self
  end

  # X共有で種を増加
  def increment_share_seed
    @success = user.increment_seed_count_by_share
    @message = success ? "Xで共有して種を増やしました！" : "本日は既にX共有で種を増やしています。"
    self
  end

  # HTMLリダイレクト用メッセージ
  def html_message_for_increment
    success ? "種を増やしました！" : message
  end

  def html_message_for_share
    message
  end
end
