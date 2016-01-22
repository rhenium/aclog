module Collector
  class NotificationQueue
    def initialize(dalli)
      @dalli = dalli
      @queue = Queue.new # not EM::Queue
      @thresholds = Settings.notification.favorites.freeze
      @clients = Settings.notification.accounts.map { |hash|
        Twitter::REST::Client.new(consumer_key: Settings.notification.consumer.key,
                                  consumer_secret: Settings.notification.consumer.secret,
                                  access_token: hash.token,
                                  access_token_secret: hash.secret)
      }.freeze
    end

    def run
      return unless Settings.notification.enabled

      while true
        ids = @queue.pop
        next if ids.empty?

        Tweet.where(id: ids).joins(user: :account).each do |tweet|
          acc = tweet.user&.account
          if acc&.active? && acc&.notification_enabled?
            perform_tweet(tweet)
          end
        end
      end
    end

    def push(ids)
      @queue << ids
    end

    private
    def perform_tweet(tweet)
      last_count = @dalli.get("notification/tweets/#{tweet.id}/favorites_count")
      @dalli.set("notification/tweets/#{tweet.id}/favorites_count", [last_count || 0, tweet.favorites_count].max)

      if last_count && (t_count = @thresholds.select { |m| last_count < m && m <= tweet.favorites_count }.last) ||
          @thresholds.include?(t_count = tweet.favorites_count)
        post("@#{tweet.user.screen_name} #{t_count}likes! #{tweet_url(tweet)}", tweet.id)
      end
    end

    def tweet_url(tweet)
      "#{Settings.base_url}/i/#{tweet.id}"
    end

    def post(text, reply_to = 0)
      @clients.each do |client|
        begin
          client.update(text, in_reply_to_status_id: reply_to)
          break
        rescue Twitter::Error::Forbidden => e
          raise e unless e.message == "User is over daily status update limit."
        end
      end
    end

    class << self
      def push(ids)
        instance.push(ids)
      end

      def instance
        @queue or raise(ArgumentError, "NotificationQueue is not initialized")
      end

      def start(dalli)
        @queue = NotificationQueue.new(dalli)
        EM.defer { @queue.run }
      end
    end
  end
end
