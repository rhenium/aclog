class Account < ActiveRecord::Base
  belongs_to :user

  def self.create_or_update(hash)
    account = where(user_id: hash[:user_id]).first_or_initialize
    account.oauth_token = hash[:oauth_token]
    account.oauth_token_secret = hash[:oauth_token_secret]
    account.consumer_version = hash[:consumer_version]
    account.save if account.changed?
    account
  end

  def update_connection
    begin
      UNIXSocket.open(File.join(Rails.root, "tmp", "sockets", "receiver.sock")) do |socket|
        socket.write({type: "register",
                      id: self.id,
                      user_id: self.user_id}.to_msgpack)
      end
    rescue Exception => ex
      # receiver not started?
      logger.error("Could't send account info to receiver daemon: #{ex}")
    end
  end

  def client
    Twitter::Client.new(
      consumer_key: Settings.collector.consumer[consumer_version].key,
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
end
