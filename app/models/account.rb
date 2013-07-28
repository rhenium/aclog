require "msgpack/rpc/transport/unix"

class Account < ActiveRecord::Base
  ACTIVE = 0; DEACTIVATED = 1

  belongs_to :user

  scope :active, -> { where(status: Account::ACTIVE) }

  def self.create_or_update(hash)
    account = where(user_id: hash[:user_id]).first_or_initialize
    account.oauth_token = hash[:oauth_token]
    account.oauth_token_secret = hash[:oauth_token_secret]
    account.consumer_version = hash[:consumer_version]
    account.status = Account::ACTIVE
    account.save if account.changed?
    account
  end

  def self.set_of_collector(collector_id)
    self.active.where("id % ? = ?", Settings.collector.count, collector_id)
  end

  def notification?; self.notification end
  def private?; self.private end
  def active?; self.status == Account::ACTIVE end

  def update_settings!(params)
    self.notification = !!params[:notification]
    self.private = !!params[:private]
    self.save! if self.changed?
    self
  end

  def deactivate!
    self.status = Account::DEACTIVATED
    self.save! if self.changed?

    update_connection
  end

  def update_connection
    transport = MessagePack::RPC::UNIXTransport.new
    client = MessagePack::RPC::Client.new(transport, Rails.root.join("tmp", "sockets", "receiver.sock").to_s)
    if self.status == Account::ACTIVE
      client.call(:register, Marshal.dump(self))
    elsif self.status == Account::DEACTIVATED
      client.call(:unregister, Marshal.dump(self))
    end
  rescue Errno::ECONNREFUSED, Errno::ENOENT
    Rails.logger.error($!)
  end

  def client
    Twitter::Client.new(consumer_key: Settings.collector.consumer[consumer_version].key,
                        consumer_secret: Settings.collector.consumer[consumer_version].secret,
                        oauth_token: oauth_token,
                        oauth_token_secret: oauth_token_secret)
  end

  def import_favorites(id)
    result = client.status_activity(id)

    # favs ユーザー一覧回収
    Favorite.from_tweet_object(result)

    # favs ユーザー回収
    client.users(result.favoriters).each do |u|
      User.from_user_object(u)
    end

    # rts 回収・RTのステータスIDを取得する必要がある
    client.retweets(id, count: 100).each do |status|
      Retweet.from_tweet_object(status)
    end
  end

  def following?(target_user_id)
    api_friendship?(user_id, target_user_id)
  end

  def followed_by?(source_user_id)
    api_friendship?(source_user_id, user_id)
  end

  private
  def api_friendship?(source_user_id, target_user_id)
    return nil unless source_user_id && source_user_id.is_a?(Integer)
    return nil unless target_user_id && target_user_id.is_a?(Integer)

    Rails.cache.fetch("friendship/#{source_user_id}-#{target_user_id}", expires_in: 3.days) do
      client.friendship?(source_user_id, target_user_id) rescue nil
    end
  end
end

