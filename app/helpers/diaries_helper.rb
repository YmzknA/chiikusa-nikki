module DiariesHelper
  def weed_color(diary)
    return default_weed_color unless diary

    intensity = StatisticsCalculatorService.new(diary.user).calculate_learning_intensity(diary)
    intensity_to_color(intensity)
  end

  private

  def intensity_to_color(intensity)
    case intensity
    when 0
      "#ebedf0" # GitHub風グレー
    when 0..1
      "#9be9a8" # 薄緑
    when 1..2
      "#40c463" # 緑
    when 2..3
      "#30a14e" # 濃緑
    else
      "#216e39" # 最高強度
    end
  end

  def default_weed_color
    "#bdba8c" # デフォルト色
  end
end
