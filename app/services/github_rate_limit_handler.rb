module GithubRateLimitHandler
  def handle_rate_limit_error(error)
    reset_time = extract_rate_limit_reset_time(error)
    wait_time = calculate_wait_time(reset_time)

    Rails.logger.warn "GitHub API rate limit exceeded. Reset at: #{reset_time}"

    {
      success: false,
      message: "GitHub API制限に達しました。#{format_wait_time(wait_time)}後に再試行してください。",
      retry_after: wait_time,
      rate_limited: true
    }
  end

  private

  def extract_rate_limit_reset_time(error)
    return nil unless error.respond_to?(:response_headers)

    reset_header = error.response_headers["X-RateLimit-Reset"] ||
                   error.response_headers["x-ratelimit-reset"]
    return nil unless reset_header

    Time.at(reset_header.to_i)
  rescue StandardError
    nil
  end

  def calculate_wait_time(reset_time)
    return 60 unless reset_time # Default 1 minute if no reset time

    wait_seconds = (reset_time - Time.current).to_i
    [wait_seconds, 0].max
  end

  def format_wait_time(seconds)
    if seconds < 60
      "#{seconds}秒"
    elsif seconds < 3600
      minutes = (seconds / 60).round
      "約#{minutes}分"
    else
      hours = (seconds / 3600).round
      "約#{hours}時間"
    end
  end
end
