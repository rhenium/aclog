class Notification
  # Notifies the count of favovorites for the tweet with tweeting a reply from notification account.
  # Notification will be send only when the count reached the specified number in settings.yml.
  # THIS METHOD IS NOT THREAD SAFE
  #
  # @param [Hash, Tweet] hash_or_tweet the target tweet.
  def self.try_notify_favorites(tweet)
    return unless Settings.notification.enabled

    notify_favs = -> c do
      account = Account.includes(:user).where(users: { id: tweet.user_id }).first
      if account && account.active? && account.notification_enabled?
        notify(account.user, "#{ c }favs!", tweet.id)
      end
    end

    last_count = Rails.cache.read("notification/tweets/#{ tweet.id }/favorites_count")
    if last_count
      t_count = Settings.notification.favorites.select {|m| last_count < m && m <= tweet.favorites_count }.last
      if t_count
        notify_favs.(t_count)
      end
    else
      if Settings.notification.favorites.include?(tweet.favorites_count)
        notify_favs.(tweet.favorites_count)
      end
    end

    Rails.cache.write("notification/tweets/#{ tweet.id }/favorites_count", [last_count || 0, tweet.favorites_count].max)
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
