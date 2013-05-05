# -*- coding: utf-8 -*-
module Aclog
  module Notification
    def self.reply_favs(tweet, count)
      reply_tweet(tweet.user, "#{count}favs!", tweet)
    end

    private
    def self.reply_tweet(user, text, tweet)
      @@account ||= Twitter::Client.new(consumer_key: Settings.notification.consumer.key,
                                        consumer_secret: Settings.notification.consumer.secret,
                                        oauth_token: Settings.notification.token[0].token,
                                        oauth_token_secret: Settings.notification.token[0].secret)

      url = Rails.application.routes.url_helpers.tweet_url(host: Settings.base_url, id: tweet.id)

      begin
        @@account.update("@#{user.screen_name} #{text} #{url}", :in_reply_to_status_id => tweet.id)
      rescue Exception
        Rails.logger.error($!)
        Rails.logger.error($@)
      end
    end
  end
end
