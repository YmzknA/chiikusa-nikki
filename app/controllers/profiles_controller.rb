class ProfilesController < ApplicationController
  include AuthorizationHelper

  before_action :authenticate_user!

  def show; end

  def edit; end

  def update
    # アバター更新時の追加検証
    if user_params[:avatar].present? && !avatar_update_allowed?
      wait_time_message = calculate_wait_time_message
      Rails.logger.warn("Avatar update blocked for user #{current_user.id}: #{wait_time_message}")
      flash.now[:alert] = wait_time_message
      return render :edit, status: :forbidden
    end

    if current_user.update(user_params)
      # アバター更新時刻を記録
      current_user.update_column(:avatar_updated_at, Time.current) if user_params[:avatar].present?
      redirect_to profile_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :avatar)
  end

  # アバター更新制限の設定値を取得
  def avatar_update_limits
    @avatar_update_limits ||= {
      update_interval_limit: Rails.application.config.avatar_update_interval_limit || 1.hour,
      account_age_limit: Rails.application.config.avatar_update_account_age_limit || 24.hours
    }
  end

  # アバター更新が許可されているかチェック
  def avatar_update_allowed?
    limits = avatar_update_limits

    # 初回アバター設定は新規アカウント制限なしで許可
    return true if current_user.avatar_updated_at.nil?

    # 新規アカウント制限チェック（2回目以降のみ）
    return false if current_user.created_at > limits[:account_age_limit].ago

    # 短時間での連続更新防止のみ適用
    current_user.avatar_updated_at < limits[:update_interval_limit].ago
  end

  # 待機時間メッセージを計算して返す
  def calculate_wait_time_message
    limits = avatar_update_limits
    current_time = Time.current

    # 初回アバター設定の場合は制限なし
    return nil if current_user.avatar_updated_at.nil?

    # 新規アカウント制限チェック（初回アバター設定でない場合のみ）
    if current_user.avatar_updated_at.present? && current_user.created_at > limits[:account_age_limit].ago
      remaining_time = limits[:account_age_limit] - (current_time - current_user.created_at)
      time_text = format_remaining_time(remaining_time)
      interval_text = format_interval_text(limits[:account_age_limit])
      return I18n.t("avatar_security.account_too_new", time: time_text, interval: interval_text)
    end

    # 更新間隔チェックのみ
    if update_too_soon?(limits[:update_interval_limit], current_time)
      remaining_time = limits[:update_interval_limit] - (current_time - current_user.avatar_updated_at)
      time_text = format_remaining_time(remaining_time)
      interval_text = format_interval_text(limits[:update_interval_limit])
      return I18n.t("avatar_security.update_too_soon", time: time_text, interval: interval_text)
    end

    # フォールバック（通常はここには到達しない）
    I18n.t("avatar_security.update_permission_denied")
  end

  # 更新間隔が短すぎるかチェック
  def update_too_soon?(update_interval_limit, _current_time)
    current_user.avatar_updated_at && current_user.avatar_updated_at >= update_interval_limit.ago
  end

  # 残り時間を人間が読みやすい形式で返す
  # @param seconds [Numeric] 残り時間（秒）
  # @return [String] 国際化対応の時間テキスト
  def format_remaining_time(seconds)
    return I18n.t("avatar_security.time_just_now") if seconds <= 0

    if seconds >= 3600
      hours = (seconds / 3600).floor
      minutes = ((seconds % 3600) / 60).floor
      return I18n.t("avatar_security.time_hours_minutes", hours: hours, minutes: minutes) if minutes.positive?

      I18n.t("avatar_security.time_hours", hours: hours)
    elsif seconds >= 60
      minutes = (seconds / 60).floor
      I18n.t("avatar_security.time_minutes", minutes: minutes)
    else
      I18n.t("avatar_security.time_seconds", seconds: seconds.ceil)
    end
  end

  # 間隔テキストを国際化対応で返す
  # @param seconds [Numeric] 間隔時間（秒）
  # @return [String] 国際化対応の間隔テキスト
  def format_interval_text(seconds)
    if seconds >= 3600
      hours = (seconds / 3600).floor
      I18n.t("avatar_security.interval_hours", hours: hours)
    elsif seconds >= 60
      minutes = (seconds / 60).floor
      I18n.t("avatar_security.interval_minutes", minutes: minutes)
    else
      I18n.t("avatar_security.interval_seconds", seconds: seconds)
    end
  end
end
