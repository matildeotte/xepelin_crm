class User < ApplicationRecord
  has_many :companies, dependent: :nullify

  validates :email, presence: true, uniqueness: true
  validates :google_uid, presence: true, uniqueness: true

  def self.from_google(auth)
    user = find_or_initialize_by(email: auth.info.email)

    user.google_uid = auth.uid
    user.name = auth.info.name.presence || auth.info.email
    user.avatar_url = auth.info.image
    user.save!
    user
  end
end
