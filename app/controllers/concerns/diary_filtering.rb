# frozen_string_literal: true

module DiaryFiltering
  extend ActiveSupport::Concern

  private

  # 月別にダイアリーをフィルタリング
  def filter_diaries_by_month(diaries, selected_month)
    return diaries if selected_month == "all"

    year, month = selected_month.split("-").map(&:to_i)
    start_date = Date.new(year, month, 1).beginning_of_month
    end_date = Date.new(year, month, 1).end_of_month
    diaries.where(date: start_date..end_date)
  end

  # 利用可能な月の一覧を取得
  def available_months
    months = current_user.diaries.pluck(:date).map { |date| date.strftime("%Y-%m") }.uniq.sort.reverse
    [%w[全て表示 all]] + months.map { |month| [format_month_label(month), month] }
  end

  # 月のラベルをフォーマット
  def format_month_label(month_string)
    year, month = month_string.split("-")
    "#{year}年#{month.to_i}月"
  end
end
