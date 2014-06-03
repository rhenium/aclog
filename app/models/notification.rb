class Notification
  def self.try_notify_favorites(hash_or_tweet)
    if hash_or_tweet.is_a?(Tweet)
      hash_or_tweet = hash_or_tweet.attributes
    end
    id = hash_or_tweet[:id]
    user_id = hash_or_tweet[:user_id]
    count = hash_or_tweet[:favorites_count]

    if Settings.notification.enabled && Settings.notification.favorites.include?(count)
      account = Account.includes(:user).where(users: { id: user_id }).first
      if account && account.active? && account.notification?
        Rails.cache.fetch("notification/tweets/#{ id }/favorites/#{ count }") do
          notify(account.user, "#{ count }favs!", id)
          true
        end
      end
    end
  end

  private
  def self.notify(user, text, id)
    url = Rails.application.routes.url_helpers.tweet_url(host: Settings.base_url, id: id)
    tweet("@#{ user.screen_name } #{ text } #{ url }", id)
  end

  def self.tweet(text, reply_to = 0)
    defer do
      begin
        cur = 0
        while cur < Settings.notification.accounts.size
          begin
            client(cur).update(text, in_reply_to_status_id: reply_to)
          rescue Twitter::Error::Forbidden => e
            if e.message = "User is over daily status update limit."
              cur += 1
            else
              raise e
            end
          end
        end
      rescue => e
        Rails.logger.error("NOTIFICATION: #{ e.class }: #{ e.message }")
      end
    end
  end

  def self.client(index)
    s = Settings.notification.accounts[index]
    Twitter::REST::Client.new(consumer_key: Settings.notification.consumer.key,
                              consumer_secret: Settings.notification.consumer.secret,
                              access_token: s.token,
                              access_token_secret: s.secret)
  end

  def self.defer(&blk)
    if EM.reactor_running?
      EM.defer &blk
    else
      Thread.new &blk
    end
  end
end
