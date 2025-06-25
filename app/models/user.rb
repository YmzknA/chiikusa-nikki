class User < ApplicationRecord
  has_many :diaries

  def self.find_or_create_from_auth_hash(auth_hash)
    user = find_or_initialize_by(github_id: auth_hash[:uid])
    user.username = auth_hash[:info][:nickname]
    user.access_token = auth_hash[:credentials][:token]
    user.save!
    user
  end
end
