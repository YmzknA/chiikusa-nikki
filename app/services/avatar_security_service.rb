# 個人開発向けのシンプルなセキュリティサービス

class AvatarSecurityService
  # 個人開発向け：最小限のセキュリティチェック

  def self.validate_url!(url)
    uri = URI.parse(url)

    # HTTPS必須（基本的なセキュリティ）
    raise SecurityError, "HTTPS URLのみ許可されています" unless uri.scheme == "https"

    # 明らかに危険なlocalhostのみブロック
    raise SecurityError, "ローカルホストへのアクセスは禁止されています" if localhost?(uri.host)

    # URLの妥当性チェック
    raise SecurityError, "無効なURLです" unless valid_url?(uri)

    url
  rescue URI::InvalidURIError
    raise SecurityError, "無効なURL形式です"
  end

  class << self
    private

    def localhost?(hostname)
      return false unless hostname

      hostname.downcase.in?(%w[localhost 127.0.0.1 ::1])
    end

    def valid_url?(uri)
      uri.host.present? && uri.host.length < 255
    end
  end
end
