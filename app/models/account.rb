require "msgpack/rpc/transport/unix"

class Account < ActiveRecord::Base
  enum status: { active: 0, inactive: 1, revoked: 2 }

  belongs_to :user
  scope :for_node, ->(block_number) { active.where("id % ? = ?", Settings.collector.nodes_count, block_number) }

  def notification_enabled?; notification_enabled end
  def deactivate!; self.inactive! end

  class << self
    def register(hash)
      account = where(user_id: hash[:user_id]).first_or_initialize
      account.oauth_token = hash[:oauth_token]
      account.oauth_token_secret = hash[:oauth_token_secret]
      account.status = :active
      account.save! if account.changed?
    end

    def random
      active.order("RAND()").first
    end
  end

  def verify_token!
    client.user
  rescue
    self.revoked!
  end

  def client
    @_client ||= Twitter::REST::Client.new(consumer_key: Settings.consumer.key,
                                           consumer_secret: Settings.consumer.secret,
                                           access_token: oauth_token,
                                           access_token_secret: oauth_token_secret)
  end

  def following?(target_id)
    target_id = target_id.id if target_id.is_a?(User)
    friends.member? target_id
  end

  def friends
    @_friends ||=
    Rails.cache.fetch("accounts/#{self.id}/friends", expires_in: Settings.cache.friends) do
      Set.new client.friend_ids
    end
  end
end
