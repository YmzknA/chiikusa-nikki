class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github]

  has_many :diaries, dependent: :destroy
  validates :github_id, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    # 既存ユーザーを探すか新規作成
    user = where(email: auth.info.email).first_or_initialize

    # 既存ユーザーでも新しい認証情報で更新
    user.assign_attributes(
      email: auth.info.email,
      github_id: auth.uid,
      username: auth.info.nickname,
      access_token: auth.credentials.token
    )

    # 新規ユーザーの場合のみパスワード設定
    user.password = Devise.friendly_token[0, 20] if user.new_record?

    user.save!
    token_status = user.access_token.present? ? 'Present' : 'Missing'
    Rails.logger.info "OAuth user updated: #{user.username} (#{user.email}) - Token: #{token_status}"
    user
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
end
