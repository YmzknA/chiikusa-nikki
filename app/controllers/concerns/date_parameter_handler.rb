# セキュリティリスクのある日付入力を適切にバリデーション・サニタイズするconcern
module DateParameterHandler
  extend ActiveSupport::Concern

  private

  # 日付パラメータを安全に解析する
  # data_param [String] 日付文字列パラメータ / default [Date] デフォルト値 / show_flash [Boolean] 無効な日付の場合にflashメッセージを表示するか
  def safe_parse_date(date_param, default: Date.current, show_flash: true)
    return default if date_param.blank?

    # 入力値の事前バリデーション（セキュリティ対策）
    unless valid_date_format?(date_param)
      handle_invalid_date_input(date_param, "無効な日付形式です", show_flash)
      return default
    end

    # 日付解析
    Date.strptime(date_param, "%Y-%m-%d")
  rescue StandardError
    handle_invalid_date_input(date_param, "日付の解析に失敗しました", show_flash)
    default
  end

  # 日付文字列の形式をチェック
  def valid_date_format?(date_string)
    return false if date_string.blank?

    # YYYY-MM-DD形式のみ許可
    date_string.match?(/\A\d{4}-\d{2}-\d{2}\z/)
  end

  # 無効な日付入力への対応
  # input[string] 入力値 / message[string] ユーザー向けエラーメッセージ / show_flash[boolean] flashメッセージを表示するか
  def handle_invalid_date_input(input, message, show_flash)
    flash.now[:warning] = message if show_flash

    Rails.logger.info "Invalid date input handled: #{input} from user_id #{current_user&.id || 'unknown'}"
  end
end
