class Account < ActiveRecord::Base
  enum status: { active: 0, inactive: 1, revoked: 2, opted_out: 3 }

  belongs_to :user
  scope :active, -> { where(status: self.statuses[:active]) }

  class << self
    # Registers a new account or updates an existing account.
    # @param [Hash] hash data
    # @return [Account] The target account object.
    def register(hash)
      account = where(user_id: hash[:user_id]).first_or_initialize
      account.oauth_token = hash[:oauth_token]
      account.oauth_token_secret = hash[:oauth_token_secret]
      account.status = :active if [:inactive, :revoked].include?(account.status)
      account.save! if account.changed?
      account
    end

    # Returns a random active account.
    # @return [Account] A random active account.
    def random
      active.order("RAND()").first
    end
  end

  # Verifies the OAuth token pair with calling /1.1/account/verify_credentials.json.
  # If the token was revoked, changes the `status` to :revoked.
  def verify_token!
    client.user
  rescue Twitter::Error::Unauthorized
    inactive!
  end

  # Returns whether following the target user or not.
  # @param [User, Integer] target_id Target user.
  # @return [Boolean] whether following the target or not.
  def following?(target_id)
    target_id = target_id.id if target_id.is_a?(User)
    friends.member? target_id
  end

  # Returns Twitter Gem's Client instance.
  # @return [Twitter::REST::Client] An instance of Twitter::REST::Client.
  def client
    Twitter::REST::Client.new(consumer_key: Settings.consumer.key,
                              consumer_secret: Settings.consumer.secret,
                              access_token: oauth_token,
                              access_token_secret: oauth_token_secret)
  end

  # Returns the array of friends.
  # @return [Array<Integer>]
  def friends
    @_friends ||=
    Rails.cache.fetch("accounts/#{self.id}/friends", expires_in: Settings.cache.friends) do
      Set.new client.friend_ids
    end
  end
end
