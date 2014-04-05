class Notification
  def self.notify_favorites_count(tweet)
    return unless Settings.notification.enabled

    if Settings.notification.favorites.include?(tweet.reload.favorites_count)
      account = Account.where(user_id: tweet.user_id).first
      if account && account.active? && account.notification?
        reply_favs(tweet, tweet.favorites_count)
      end
    end
  end

  def self.reply_favs(tweet, count)
    url = Rails.application.routes.url_helpers.tweet_url(host: Settings.base_url, id: tweet.id)
    tweet("@#{tweet.user.screen_name} #{count}favs! #{url}", tweet.id)
  end

  private
  def self.tweet(text, reply_to = 0)
    s = proc do
      cur = Rails.cache.read("notification_account") || 0
      if Settings.notification.accounts[cur]
        begin
          client = Twitter::REST::Client.new(consumer_key: Settings.notification.consumer.key,
                                             consumer_secret: Settings.notification.consumer.secret,
                                             access_token: Settings.notification.accounts[cur].token,
                                             access_token_secret: Settings.notification.accounts[cur].secret)

          client.update(text, in_reply_to_status_id: reply_to)
        rescue Twitter::Error::AlreadyPosted
          # Status is a duplicate.
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

    if EM.reactor_running?
      EM.defer &s
    else
      Thread.new &s
    end
  end
end
