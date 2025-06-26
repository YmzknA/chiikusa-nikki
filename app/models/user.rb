class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github]

  has_many :diaries
  validates :github_id, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = user.random_email
      user.password = Devise.friendly_token[0, 20]
      user.github_id = auth.uid
      user.username = auth.info.nickname
      user.access_token = auth.credentials.token
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
    "#{ key }@email.com"
  end
    
end
