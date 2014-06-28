class Notification
  def self.try_notify_favorites(hash_or_tweet)
    if hash_or_tweet.is_a?(Tweet)
      hash_or_tweet = hash_or_tweet.attributes
    end
    id = hash_or_tweet[:id]
    user_id = hash_or_tweet[:user_id]
    count = hash_or_tweet[:favorites_count]

    if Settings.notification.enabled && Settings.notification.favorites.include?(count)
      Rails.cache.fetch("notification/tweets/#{ id }/favorites/#{ count }") do
        account = Account.includes(:user).where(users: { id: user_id }).first
        if account && account.active? && account.notification_enabled?
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
        Settings.notification.accounts.each do |hash|
          begin
            client(hash).update(text, in_reply_to_status_id: reply_to)
            break
          rescue Twitter::Error::Forbidden => e
            raise e unless e.message = "User is over daily status update limit."
          end
        end
      rescue => e
        Rails.logger.error("NOTIFICATION: #{ e.class }: #{ e.message }")
      end
    end
  end

  def self.client(acc)
    @_client ||= {}
    @_client[acc] ||= 
      Twitter::REST::Client.new(consumer_key: Settings.notification.consumer.key,
                                consumer_secret: Settings.notification.consumer.secret,
                                access_token: acc.token,
                                access_token_secret: acc.secret)
  end

  def self.defer(&blk)
    if EM.reactor_running?
      EM.defer &blk
    else
      Thread.new &blk
    end
  end
end
