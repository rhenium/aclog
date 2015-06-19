class TweetResponseNotificationJob < ActiveJob::Base
  queue_as :default

  # Notifies the count of favovorites for the tweet with tweeting a reply from notification account.
  # Notification will be send only when the count reached the specified number in settings.yml.
  # THIS METHOD IS NOT THREAD SAFE
  #
  # @param [Hash, Tweet] hash_or_tweet the target tweet.
  def perform(tweet)
    return unless Settings.notification.enabled

    last_count = Rails.cache.read("notification/tweets/#{ tweet.id }/favorites_count")
    Rails.cache.write("notification/tweets/#{ tweet.id }/favorites_count", [last_count || 0, tweet.favorites_count].max)

    if last_count
      t_count = Settings.notification.favorites.select {|m| last_count < m && m <= tweet.favorites_count }.last
    else
      t_count = Settings.notification.favorites.include?(tweet.favorites_count) || tweet.favorites_count
    end

    if t_count
      notify(tweet, "#{ t_count }favs!")
    end
  end

  private
  def notify(tweet, text)
    user = tweet.user
    account = user.account

    if account && account.active? && account.notification_enabled?
      url = Rails.application.routes.url_helpers.tweet_url(host: Settings.base_url, id: tweet.id)
      post("@#{ user.screen_name } #{ text } #{ url }", tweet.id)
    end
  end

  def post(text, reply_to = 0)
    Settings.notification.accounts.each do |hash|
      begin
        client(hash).update(text, in_reply_to_status_id: reply_to)
        break
      rescue Twitter::Error::Forbidden => e
        raise e unless e.message = "User is over daily status update limit."
      end
    end
  end

  def client(acc)
    @_client ||= {}
    @_client[acc] ||= 
      Twitter::REST::Client.new(consumer_key: Settings.notification.consumer.key,
                                consumer_secret: Settings.notification.consumer.secret,
                                access_token: acc.token,
                                access_token_secret: acc.secret)
  end
end
