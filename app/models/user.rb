# rubocop:disable Metrics/ClassLength
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :rememberable,
         :omniauthable, omniauth_providers: [:github, :google_oauth2]

  has_many :diaries, dependent: :destroy

  # OAuth認証に必要な検証（少なくとも一つのプロバイダーIDが必要）
  validate :at_least_one_provider_id
  validate :providers_consistency
  validates :github_id, uniqueness: true, allow_nil: true
  validates :google_id, uniqueness: true, allow_nil: true

  # メールアドレス検証（一意性は不要）
  validates :email, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\z/ }

  # パスワード検証（OAuth認証のみの場合は不要な場合もある）
  validates :password, length: { minimum: 6 }, allow_blank: true

  # Encrypt access tokens for security
  encrypts :encrypted_access_token, deterministic: false
  encrypts :encrypted_google_access_token, deterministic: false

  # プロバイダー管理のためのシリアライズ
  serialize :providers, type: Array, coder: JSON

  def self.from_omniauth(auth, current_user = nil)
    provider = auth.provider
    uid = auth.uid
    email = auth.info.email

    # ログイン中のユーザーがいる場合は、そのユーザーに認証を追加
    return add_provider_to_user(current_user, auth) if current_user

    # ログアウト状態での通常の認証フロー
    user = find_existing_user_for_oauth(provider, uid, email)

    # プロバイダー別の属性設定
    attributes = build_oauth_attributes(auth, user)
    user.assign_attributes(attributes)

    # プロバイダーリストを更新
    user.providers ||= []
    user.providers << provider unless user.providers.include?(provider)

    # 新規ユーザーの場合のみパスワード設定
    user.password = Devise.friendly_token[0, 20] if user.new_record?

    user.save!
    Rails.logger.info "OAuth user created/updated: #{user.username} (#{user.email}) - Provider: #{provider}"
    user
  end

  def self.add_provider_to_user(user, auth)
    provider = auth.provider
    uid = auth.uid

    validate_provider_not_taken(provider, uid, user.id)
    assign_provider_attributes(user, auth)
    update_user_providers(user, provider)

    user.save!
    Rails.logger.info "Provider #{provider} added to existing user #{user.id}: #{user.username}"
    user
  end

  def self.validate_provider_not_taken(provider, uid, user_id)
    existing_user = find_existing_provider_user(provider, uid, user_id)
    return unless existing_user

    Rails.logger.warn "Provider #{provider} with uid #{uid} already linked to another user #{existing_user.id}"
    raise StandardError, "この#{provider}アカウントは既に別のユーザーに連携されています"
  end

  def self.find_existing_provider_user(provider, uid, user_id)
    case provider
    when "github"
      where(github_id: uid).where.not(id: user_id).first
    when "google_oauth2"
      where(google_id: uid).where.not(id: user_id).first
    end
  end

  def self.assign_provider_attributes(user, auth)
    provider = auth.provider
    uid = auth.uid
    email = auth.info.email

    case provider
    when "github"
      user.assign_attributes(
        github_id: uid,
        username: user.username.presence || auth.info.nickname || auth.info.name,
        encrypted_access_token: auth.credentials.token
      )
    when "google_oauth2"
      user.assign_attributes(
        google_id: uid,
        google_email: email,
        username: user.username.presence || auth.info.name || auth.info.email.split("@").first,
        encrypted_google_access_token: auth.credentials.token
      )
    end
  end

  def self.update_user_providers(user, provider)
    user.providers ||= []
    user.providers << provider unless user.providers.include?(provider)
  end

  class << self
    private

    def find_existing_user_for_oauth(provider, uid, _email)
      # プロバイダーIDでのみ検索し、メールアドレスでの結合は行わない
      # これにより、ログアウト状態では同じメールでも別ユーザーとして作成される
      case provider
      when "github"
        where(github_id: uid).first || new
      when "google_oauth2"
        where(google_id: uid).first || new
      else
        new
      end
    end

    def build_oauth_attributes(auth, user)
      provider = auth.provider
      uid = auth.uid
      email = auth.info.email

      attributes = { email: email }

      case provider
      when "github"
        attributes.merge!(
          github_id: uid,
          username: auth.info.nickname || auth.info.name,
          encrypted_access_token: auth.credentials.token
        )
      when "google_oauth2"
        attributes.merge!(
          google_id: uid,
          google_email: email,
          username: user.username || auth.info.name || auth.info.email.split("@").first,
          encrypted_google_access_token: auth.credentials.token
        )
      end

      attributes
    end
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  def random_email
    key = SecureRandom.uuid
    "#{key}@email.com"
  end

  def github_repo_configured?
    github_repo_name.present?
  end

  # Accessor method for encrypted access token
  def access_token
    return nil if encrypted_access_token.blank?

    begin
      encrypted_access_token
    rescue ActiveRecord::Encryption::Errors::Decryption => e
      Rails.logger.warn "Failed to decrypt access token for user #{id}: #{e.message}"
      # Clear invalid encrypted token
      update_column(:encrypted_access_token, nil)
      nil
    end
  end

  def access_token=(token)
    self.encrypted_access_token = token
  end

  def github_service
    @github_service ||= GithubService.new(self)
  end

  def setup_github_repository(repo_name)
    return { success: false, message: "リポジトリ名を入力してください" } if repo_name.blank?

    result = github_service.create_repository(repo_name)
    update!(github_repo_name: repo_name) if result[:success]
    result
  end

  def verify_github_repository?
    return false unless github_repo_configured?

    github_service.repository_exists?(github_repo_name)
  end

  def reset_github_repository
    self.github_repo_name = nil
    save!
    github_service.reset_all_diaries_upload_status
  end

  def reset_github_access
    self.encrypted_access_token = nil
    self.github_repo_name = nil
    save!
  end

  # Google認証用のアクセストークン取得
  def google_access_token
    return nil if encrypted_google_access_token.blank?

    begin
      encrypted_google_access_token
    rescue ActiveRecord::Encryption::Errors::Decryption => e
      Rails.logger.warn "Failed to decrypt Google access token for user #{id}: #{e.message}"
      update_column(:encrypted_google_access_token, nil)
      nil
    end
  end

  def google_access_token=(token)
    self.encrypted_google_access_token = token
  end

  # プロバイダー確認メソッド
  def github_auth?
    github_id.present? && encrypted_access_token.present?
  end

  def google_auth?
    google_id.present? && encrypted_google_access_token.present?
  end

  def connected_providers
    providers || []
  end

  def github_connected?
    connected_providers.include?("github")
  end

  def google_connected?
    connected_providers.include?("google_oauth2")
  end

  # プロバイダー管理メソッド
  def can_link_provider?(provider)
    !connected_providers.include?(provider)
  end

  def increment_seed_count
    return false if last_seed_incremented_at&.today?
    return false if seed_count >= 5

    increment!(:seed_count)
    update!(last_seed_incremented_at: Time.current)
    true
  end

  def increment_seed_count_by_share
    return false if last_shared_at&.today?
    return false if seed_count >= 5

    increment!(:seed_count)
    update!(last_shared_at: Time.current)
    true
  end

  def can_increment_seed_count?
    !last_seed_incremented_at&.today? && seed_count < 5
  end

  def can_increment_seed_count_by_share?
    !last_shared_at&.today? && seed_count < 5
  end

  private

  def at_least_one_provider_id
    return if github_id.present? || google_id.present?

    errors.add(:base, "少なくとも一つの認証プロバイダーが必要です")
  end

  def providers_consistency
    providers_array = providers || []
    validate_github_provider_consistency(providers_array)
    validate_google_provider_consistency(providers_array)
  end

  def validate_github_provider_consistency(providers_array)
    return unless github_inconsistent?(providers_array)

    if github_id.present?
      errors.add(:providers, "GitHub IDが存在しますが、プロバイダーリストに含まれていません")
    else
      errors.add(:providers, "プロバイダーリストにGitHubが含まれていますが、GitHub IDが設定されていません")
    end
  end

  def validate_google_provider_consistency(providers_array)
    return unless google_inconsistent?(providers_array)

    if google_id.present?
      errors.add(:providers, "Google IDが存在しますが、プロバイダーリストに含まれていません")
    else
      errors.add(:providers, "プロバイダーリストにGoogleが含まれていますが、Google IDが設定されていません")
    end
  end

  def github_inconsistent?(providers_array)
    (github_id.present? && !providers_array.include?("github")) ||
      (github_id.blank? && providers_array.include?("github"))
  end

  def google_inconsistent?(providers_array)
    (google_id.present? && !providers_array.include?("google_oauth2")) ||
      (google_id.blank? && providers_array.include?("google_oauth2"))
  end
end
# rubocop:enable Metrics/ClassLength
