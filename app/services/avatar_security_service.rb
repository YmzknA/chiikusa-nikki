class AvatarSecurityService
  # 設定可能なセキュリティポリシー
  SECURITY_POLICIES = {
    strict: {
      allowed_schemes: %w[https],
      block_private_ips: true,
      max_hostname_length: 255,
      timeout: 5.seconds
    },
    moderate: {
      allowed_schemes: %w[https http],
      block_private_ips: true,
      max_hostname_length: 255,
      timeout: 10.seconds
    }
  }.freeze

  def self.validate_url!(url, policy: :strict)
    uri = URI.parse(url)
    config = SECURITY_POLICIES[policy]

    # スキームの検証
    raise SecurityError, I18n.t("avatar_security.https_required") unless config[:allowed_schemes].include?(uri.scheme)

    # プライベートIPアドレスのブロック
    if config[:block_private_ips] && localhost?(uri.host)
      raise SecurityError, I18n.t("avatar_security.localhost_forbidden")
    end

    # URLの妥当性チェック
    raise SecurityError, I18n.t("avatar_security.invalid_url") unless valid_url?(uri, config)

    url
  rescue URI::InvalidURIError
    raise SecurityError, I18n.t("avatar_security.invalid_url_format")
  end

  class << self
    private

    def localhost?(hostname)
      return false unless hostname

      # 基本的なローカルホスト検証
      return true if hostname.downcase.in?(%w[localhost 127.0.0.1 ::1])

      # プライベートIPアドレス範囲の検証
      private_ip_ranges = [
        IPAddr.new("10.0.0.0/8"),
        IPAddr.new("172.16.0.0/12"),
        IPAddr.new("192.168.0.0/16")
      ]

      begin
        ip = IPAddr.new(hostname)
        private_ip_ranges.any? { |range| range.include?(ip) }
      rescue IPAddr::InvalidAddressError
        false
      end
    end

    def valid_url?(uri, config)
      uri.host.present? && uri.host.length < config[:max_hostname_length]
    end
  end
end
