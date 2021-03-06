class User < ActiveRecord::Base
  has_many :hops

  def self.from_omniauth auth
    where(auth.slice "provider", "uid").first || create_from_omniauth(auth)
  end

  def self.create_from_omniauth auth
    create! do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.email = auth.info.email
      user.image = auth.info.image
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at auth.credentials.expires_at
    end
  end

  def facebook
    @facebook ||= Koala::Facebook::API.new oauth_token
    block_given? ? yield(@facebook) : @facebook
  rescue Koala::Facebook::APIError => e
    logger.info e.to_s
    nil
  end

  def friends
    @friends ||= begin
      facebook_friends = facebook { |fb| fb.get_connection :me, :friends }
      if facebook_friends.present?
        friend_ids = facebook_friends.map { |friend| friend.fetch('id').to_s }
        User.where uid: friend_ids
      end
    end
  end

end

# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  provider         :string(255)
#  uid              :string(255)
#  name             :string(255)
#  email            :string(255)
#  image            :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  oauth_token      :string(255)
#  oauth_expires_at :datetime
#

