module Collector
  class NotificationQueue
    def initialize
      @queue = Queue.new # not EM::Queue
    end

    def run
      return unless Settings.notification.enabled

      while true
        ids = @queue.pop
        next if ids.empty?

        Tweet.where(id: ids).includes(user: :account).each do |tweet|
          perform_tweet(tweet)
        end
      end
    end

    def push(ids)
      @queue << ids
    end

    private
    def perform_tweet(tweet)
      last_count = Rails.cache.read("notification/tweets/#{tweet.id}/favorites_count")
      Rails.cache.write("notification/tweets/#{tweet.id}/favorites_count", [last_count || 0, tweet.favorites_count].max)

      if last_count
        t_count = Settings.notification.favorites.select { |m| last_count < m && m <= tweet.favorites_count }.last
      else
        t_count = Settings.notification.favorites.include?(tweet.favorites_count) && tweet.favorites_count
      end

      if t_count
        notify(tweet, "#{t_count}likes!")
      end
    end

    def notify(tweet, text)
      user = tweet.user
      account = user.account

      if account && account.active? && account.notification_enabled?
        post("@#{user.screen_name} #{text} #{Settings.base_url}/i/#{tweet.id}", tweet.id)
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

    class << self
      def push(ids)
        instance.push(ids)
      end

      def instance
        @queue or raise(ArgumentError, "NotificationQueue is not initialized")
      end

      def start
        @queue = NotificationQueue.new
        EM.defer { @queue.run }
      end
    end
  end
end
