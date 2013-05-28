class Notification
  def self.notify_favorite(tweet)
    if Settings.notification.favorites.include?(tweet.favorites.count)
      if tweet.user.registered? && tweet.user.account.notification?
        reply_favs(tweet, tweet.favorites.count)
      end
    end
  end

  def self.reply_favs(tweet, count)
    Thread.new do
      url = Rails.application.routes.url_helpers.tweet_url(host: Settings.base_url, id: tweet.id)
      tweet("@#{tweet.user.screen_name} #{count}favs! #{url}", tweet.id)
    end
  end

  private
  def self.tweet(text, reply_to = 0)
    cur = Rails.cache.read("notification_account") || 0
    if Settings.notification.token[cur]
      begin
        client = Twitter::Client.new(consumer_key: Settings.notification.consumer.key,
                                     consumer_secret: Settings.notification.consumer.secret,
                                     oauth_token: Settings.notification.token[cur].token,
                                     oauth_token_secret: Settings.notification.token[cur].secret)


        client.update(text, in_reply_to_status_id: reply_to)
      rescue Exception
        cur += 1
        doretry = true
        Rails.logger.error($!)
      end
      Rails.cache.write("notification_account", cur, expires_in: 15.minutes)
      tweet(text, reply_to) if doretry
    else
      # wait for expiring notification_account cache
      #cur = 0
    end
  end
end
